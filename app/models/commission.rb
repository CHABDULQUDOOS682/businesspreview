class Commission < ApplicationRecord
  belongs_to :business
  belongs_to :user
  belongs_to :payment_invoice
  belongs_to :approved_by, class_name: "User", optional: true

  STATUSES = %w[pending approved paid_out voided].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :kind, inclusion: { in: CommissionRate::KINDS }
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :base_amount, :commission_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :month_number, presence: true, if: :subscription?
  validates :month_number, absence: true, if: :one_time?
  validates :payment_invoice_id, uniqueness: { scope: :month_number }

  scope :for_employee, ->(user) { where(user: user) }
  scope :pending, -> { where(status: "pending") }

  before_validation :calculate_commission_amount

  def subscription?
    kind == "subscription"
  end

  def one_time?
    kind == "one_time"
  end

  def approve!(approving_user, percentage_override: nil)
    unless status == "pending"
      errors.add(:status, "must be pending before approval")
      raise ActiveRecord::RecordInvalid, self
    end

    transaction do
      if percentage_override.present?
        new_percentage = BigDecimal(percentage_override.to_s)
        if new_percentage != percentage
          self.percentage = new_percentage
          self.commission_amount = (base_amount * new_percentage / 100).round(2)

          EmployeeCommissionRate.upsert_rate!(
            user: user,
            kind: kind,
            month_number: month_number,
            percentage: new_percentage
          )
        end
      end

      self.status = "approved"
      self.approved_at = Time.current
      self.approved_by = approving_user
      save!
    end
  end

  def mark_paid_out!
    unless status == "approved"
      errors.add(:status, "must be approved before payout")
      raise ActiveRecord::RecordInvalid, self
    end

    update!(
      status: "paid_out",
      paid_out_at: Time.current
    )
  end

  def self.build_for_paid_invoice!(payment_invoice)
    business = payment_invoice.business
    sold_by = business&.sold_by

    if sold_by.blank?
      Rails.logger.warn("[Commission] Business #{business&.id || 'unknown'} has no sold_by attributed user; skipping commission.")
      return nil
    end

    kind = payment_invoice.kind
    month_number = nil

    if kind == "subscription"
      # Find all paid subscription invoices for this business
      invoices = business.payment_invoices
        .where(kind: "subscription", status: "paid")
        .order(:paid_at, :id)

      index = invoices.index { |inv| inv.id == payment_invoice.id }
      # fallback if not found in list (e.g. if loaded before update finalized in query cache)
      month_number = index ? index + 1 : (invoices.count + 1)

      if month_number > 3
        # No commission is created for the 4th+ paid invoice on the same subscription cycle.
        return nil
      end
    else
      # Idempotency check for one_time sale commission to avoid duplicates
      if exists?(payment_invoice_id: payment_invoice.id)
        Rails.logger.warn("[Commission] Commission already exists for one_time payment_invoice ##{payment_invoice.id}; skipping.")
        return nil
      end
    end

    # Resolve percentage: Tier 1 (Business Override) -> Tier 2 (Employee Default) -> Tier 3 (Global Default)
    percentage = resolve_percentage(business, sold_by, kind, month_number)

    # Base amount is in dollars
    base_amount = payment_invoice.amount

    create!(
      business: business,
      user: sold_by,
      payment_invoice: payment_invoice,
      kind: kind,
      month_number: month_number,
      base_amount: base_amount,
      percentage: percentage,
      status: "pending"
    )
  end

  private

  def calculate_commission_amount
    if base_amount.present? && percentage.present?
      self.commission_amount = (base_amount * percentage / 100).round(2)
    end
  end

  def self.resolve_percentage(business, user, kind, month_number)
    # Tier 1: Business Override
    rate = BusinessCommissionRate.find_by(business: business, kind: kind, month_number: month_number)&.percentage
    return rate unless rate.nil?

    # Tier 2: Employee Default
    rate = EmployeeCommissionRate.find_by(user: user, kind: kind, month_number: month_number)&.percentage
    return rate unless rate.nil?

    # Tier 3: Global Default
    rate = CommissionRate.find_by(kind: kind, month_number: month_number)&.percentage
    return rate unless rate.nil?

    # Fallback default
    0.0
  end
end
