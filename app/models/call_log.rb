# frozen_string_literal: true

class CallLog < ApplicationRecord
  belongs_to :business, optional: true
  belongs_to :user, optional: true

  validates :direction, inclusion: { in: %w[inbound outbound] }
  validates :twilio_call_sid, uniqueness: true, allow_nil: true

  scope :recent_first, -> { order(created_at: :desc) }
  scope :outbound, -> { where(direction: "outbound") }
  scope :inbound, -> { where(direction: "inbound") }

  def duration_label
    return "-" if duration_seconds.blank? || duration_seconds.zero?

    minutes = duration_seconds / 60
    seconds = duration_seconds % 60
    format("%d:%02d", minutes, seconds)
  end

  def direction_label
    direction.to_s.titleize
  end

  def employee_name
    user&.display_name || "Unknown employee"
  end

  def sid
    twilio_call_sid
  end

  def logged_at
    created_at
  end
end
