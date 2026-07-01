class CommissionRate < ApplicationRecord
  KINDS = %w[one_time subscription].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :month_number, presence: true, if: :subscription?
  validates :month_number, absence: true, if: :one_time?
  validates :kind, uniqueness: { scope: :month_number }

  def subscription?
    kind == "subscription"
  end

  def one_time?
    kind == "one_time"
  end

  def self.default_for(kind, month_number = nil)
    find_by(kind: kind, month_number: month_number)&.percentage
  end
end
