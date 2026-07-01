class EmployeeCommissionRate < ApplicationRecord
  belongs_to :user

  KINDS = %w[one_time subscription].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :month_number, presence: true, if: :subscription?
  validates :month_number, absence: true, if: :one_time?
  validates :user_id, uniqueness: { scope: [ :kind, :month_number ] }

  def subscription?
    kind == "subscription"
  end

  def one_time?
    kind == "one_time"
  end

  def self.rate_for(user, kind, month_number = nil)
    find_by(user: user, kind: kind, month_number: month_number)&.percentage
  end

  def self.upsert_rate!(user:, kind:, month_number:, percentage:)
    rate = find_or_initialize_by(user: user, kind: kind, month_number: month_number)
    rate.update!(percentage: percentage)
    rate
  end
end
