# frozen_string_literal: true

class AgencyTask < ApplicationRecord
  SOURCES = %w[content_update].freeze
  STATUSES = %w[pending in_progress completed rejected].freeze

  belongs_to :business

  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :external_id, presence: true, uniqueness: { scope: :source }
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :newest_first, -> { order(Arel.sql("COALESCE(requested_at, created_at) DESC"), id: :desc) }
  scope :with_status, ->(status) { status.present? ? where(status: status) : all }
  scope :search, ->(query) {
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where(
      "title ILIKE :q OR description ILIKE :q OR business_number ILIKE :q OR requester_email ILIKE :q OR requester_name ILIKE :q",
      q: pattern
    )
  }

  def status_label
    status.to_s.humanize
  end
end
