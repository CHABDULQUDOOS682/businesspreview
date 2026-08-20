class Business < ApplicationRecord
  has_many :preview_links, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :meetings, dependent: :destroy
  has_many :call_logs, dependent: :nullify
  has_many :payment_invoices, dependent: :destroy
  has_many :reviews, dependent: :destroy
  belongs_to :sold_by, class_name: "User", optional: true
  belongs_to :assigned_to, class_name: "User", optional: true
  has_many :commissions, dependent: :destroy
  has_many :business_commission_rates, dependent: :destroy
  has_many :agency_tasks, dependent: :destroy
  alias_attribute :website, :website_url

  before_validation :normalize_phone
  before_validation :normalize_business_number
  before_validation :sync_assigned_at
  before_create :generate_review_token

  validates :name, presence: true
  validates :phone, presence: true
  validates :phone, uniqueness: { case_sensitive: false }, if: -> { phone.present? }
  validates :business_number, uniqueness: { case_sensitive: false }, allow_nil: true
  validate :assigned_to_must_be_employee, if: -> { assigned_to_id.present? }
  validate :employee_report_required_for_done
  validate :completion_notes_required_for_completed

  SUBSCRIPTION_PAYMENT_STATUSES = %w[inactive current past_due suspended].freeze
  SUBSCRIPTION_BILLING_CYCLE = 30.days

  SEGMENTS = {
    "nurture" => "Neutral",
    "purchased" => "Purchased Website",
    "subscriptions" => "Subscriptions"
  }.freeze

  WORK_STATUSES = {
    "assigned" => "Assigned",
    "in_progress" => "In Progress",
    "done" => "Done",
    "completed" => "Completed"
  }.freeze

  validates :subscription_payment_status, inclusion: { in: SUBSCRIPTION_PAYMENT_STATUSES }
  validates :work_status, inclusion: { in: WORK_STATUSES.keys }, allow_nil: true

  scope :with_active_subscription, -> {
    where("subscription = ? OR subscription_fee IS NOT NULL", true)
  }
  scope :with_purchased_website, -> {
    where.not(sold_price: nil)
  }
  scope :nurture_pipeline, -> {
    where(sold_price: nil, subscription_fee: nil, subscription: [ false, nil ])
  }
  scope :purchased_pipeline, -> {
    with_purchased_website.where(subscription_fee: nil, subscription: [ false, nil ])
  }
  scope :subscriptions_pipeline, -> {
    with_active_subscription
  }
  scope :assigned_to_user, ->(user) { where(assigned_to_id: user.id) }
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :with_work_status, ->(status) { where(work_status: status) }
  scope :subscription_billing_due, -> {
    with_active_subscription
      .where(subscription_payment_status: %w[current past_due])
      .where.not(subscription_fee: nil)
      .where("sold_price_paid_at IS NOT NULL OR sold_price IS NULL")
      .where("next_subscription_invoice_at IS NOT NULL AND next_subscription_invoice_at <= ?", Time.current)
      .where(<<~SQL.squish)
        NOT EXISTS (
          SELECT 1 FROM payment_invoices
          WHERE payment_invoices.business_id = businesses.id
            AND payment_invoices.kind = 'subscription'
            AND payment_invoices.status IN ('invoice_sent', 'opened')
        )
      SQL
  }

  def self.normalize_segment(segment)
    segment = segment.to_s
    SEGMENTS.key?(segment) ? segment : "nurture"
  end

  scope :for_segment, ->(segment) {
    case normalize_segment(segment)
    when "purchased"
      purchased_pipeline
    when "subscriptions"
      subscriptions_pipeline
    else
      nurture_pipeline
    end
  }

  def self.segment_counts
    SEGMENTS.keys.index_with { |segment| for_segment(segment).count }
  end

  def self.segment_unread_counts
    SEGMENTS.keys.index_with do |segment|
      Message.inbound.unread.where(business_id: for_segment(segment).select(:id)).count
    end
  end

  def business_segment
    return "subscriptions" if subscription_active?
    return "purchased" if sold_price.present?

    "nurture"
  end

  def business_segment_label
    SEGMENTS.fetch(business_segment)
  end

  def work_status_label
    return "Unassigned" if work_status.blank?

    WORK_STATUSES.fetch(work_status, work_status.to_s.humanize)
  end

  def self.normalize_work_status(status)
    status = status.to_s
    WORK_STATUSES.key?(status) ? status : nil
  end

  def subscription_active?
    subscription? || subscription_fee.present?
  end

  def subscription_first_invoice?(excluding: nil)
    scope = payment_invoices.where(kind: "subscription").where.not(status: %w[draft failed])
    scope = scope.where.not(id: excluding.id) if excluding&.id
    scope.none?
  end

  def sold_price_collected?
    sold_price.blank? || sold_price_paid_at.present? || payment_invoices.where(kind: "one_time", status: "paid").exists?
  end

  def needs_initial_sold_price_invoice?
    subscription_active? && sold_price.present? && !sold_price_collected?
  end

  def manual_invoice_available?
    if subscription_active?
      needs_initial_sold_price_invoice?
    else
      sold_price.present? && !payment_invoices.where(kind: "one_time", status: "paid").exists?
    end
  end

  def due_for_subscription_billing?
    return false unless subscription_active?
    return false unless sold_price_collected?
    return false if subscription_fee.blank?
    return false if next_subscription_invoice_at.blank? || next_subscription_invoice_at > Time.current
    return false if payment_invoices.where(kind: "subscription", status: %w[invoice_sent opened]).exists?

    true
  end

  def subscription_payment_current?
    subscription_payment_status == "current"
  end

  def subscription_payment_past_due?
    subscription_payment_status == "past_due"
  end

  def subscription_suspended?
    subscription_payment_status == "suspended"
  end

  def subscription_payment_status_label
    case subscription_payment_status
    when "current" then "Payment Current"
    when "past_due" then "Payment Overdue"
    when "suspended" then "Suspended"
    else "Inactive"
    end
  end

  def activate_subscription_billing!(anchor_at: Time.current)
    return unless subscription_active?
    return unless sold_price_collected?
    return if subscription_fee.blank?

    update!(
      subscription_billing_anchor_at: anchor_at,
      next_subscription_invoice_at: anchor_at + SUBSCRIPTION_BILLING_CYCLE,
      subscription_payment_status: "current"
    )
  end

  def review_url
    Rails.application.routes.url_helpers.new_review_submission_url(
      token: review_token,
      host: ENV.fetch("APP_HOST", "localhost"),
      protocol: ENV.fetch("APP_PROTOCOL", "https")
    )
  end

  private

  def normalize_phone
    return if phone.blank?

    digits = phone.to_s.gsub(/[^\d+]/, "")
    digits = "+#{digits.delete('+')}" if digits.present?
    self.phone = digits
  end

  def normalize_business_number
    value = business_number.to_s.strip.upcase
    self.business_number = value.presence
  end

  def generate_review_token
    self.review_token ||= SecureRandom.urlsafe_base64(16)
  end

  def sync_assigned_at
    if assigned_to_id.blank?
      self.assigned_at = nil
      self.work_status = nil if assigned_to_id_changed?
    elsif assigned_to_id_changed?
      self.assigned_at = Time.current
      self.work_status = "assigned"
    end
  end

  def assigned_to_must_be_employee
    return if assigned_to&.role_employee?

    errors.add(:assigned_to, "must be an employee")
  end

  def employee_report_required_for_done
    return unless work_status == "done"
    return if employee_report.to_s.strip.present?

    errors.add(:employee_report, "is required when marking done")
  end

  def completion_notes_required_for_completed
    return unless work_status == "completed"
    return if completion_notes.to_s.strip.present?

    errors.add(:completion_notes, "are required when marking completed")
  end
end
