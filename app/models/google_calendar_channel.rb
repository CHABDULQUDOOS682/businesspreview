class GoogleCalendarChannel < ApplicationRecord
  validates :channel_id, :resource_id, :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at.blank? || expires_at <= Time.current
  end
end
