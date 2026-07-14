class AvailabilityRule < ApplicationRecord
  belongs_to :user

  validates :day_of_week, inclusion: { in: 0..6 }
  validates :start_minute, :end_minute, presence: true
  validate :end_after_start

  scope :active, -> { where(active: true) }
  scope :for_day, ->(wday) { where(day_of_week: wday) }

  def start_time_on(date)
    date.in_time_zone.beginning_of_day + start_minute.minutes
  end

  def end_time_on(date)
    date.in_time_zone.beginning_of_day + end_minute.minutes
  end

  private

  def end_after_start
    return if start_minute.blank? || end_minute.blank?

    errors.add(:end_minute, "must be after start time") if end_minute <= start_minute
  end
end
