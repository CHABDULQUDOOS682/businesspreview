class Meeting < ApplicationRecord
  DEFAULT_COMPANY_EMAIL = "devdebizz@gmail.com".freeze
  STATUSES = %w[scheduled completed cancelled no_show].freeze
  DEFAULT_DURATION_MINUTES = 30

  belongs_to :user
  belongs_to :business

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    cancelled: "cancelled",
    no_show: "no_show"
  }, validate: true

  before_validation :generate_public_token, on: :create

  validates :client_name, :client_email, :title, :starts_at, :duration_minutes, presence: true
  validates :client_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate :starts_at_cannot_be_in_the_past, on: :create
  validate :starts_at_cannot_move_to_past, on: :update, if: :will_save_change_to_starts_at?
  validate :no_employee_overlap, if: :overlap_validation_needed?
  validate :no_calendar_overlap, if: :overlap_validation_needed?

  scope :for_employee, ->(employee) { where(user: employee) }
  scope :upcoming, -> { scheduled.where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :recent_first, -> { order(starts_at: :desc) }
  scope :on_date, ->(date) {
    day = date.to_date
    where(starts_at: day.beginning_of_day..day.end_of_day)
  }
  scope :overlapping, ->(start_time, end_time, excluding_id: nil) {
    relation = scheduled.where("starts_at < ? AND (starts_at + (duration_minutes * INTERVAL '1 minute')) > ?", end_time, start_time)
    excluding_id.present? ? relation.where.not(id: excluding_id) : relation
  }

  def self.company_email
    ENV.fetch("GOOGLE_COMPANY_EMAIL", DEFAULT_COMPANY_EMAIL)
  end

  def ends_at
    starts_at + duration_minutes.minutes
  end

  def attendee_emails
    organizer_email = user.role_employee? ? user.email : self.class.company_email

    [ client_email, organizer_email, self.class.company_email ]
      .map { |email| email.to_s.strip.downcase }
      .uniq
  end

  def cancellable?
    scheduled? && google_event_id.present?
  end

  def editable?
    scheduled?
  end

  private

  def generate_public_token
    self.public_token ||= SecureRandom.hex(12)
  end

  def overlap_validation_needed?
    scheduled? && starts_at.present? && duration_minutes.present?
  end

  def starts_at_cannot_be_in_the_past
    return if starts_at.blank?

    errors.add(:starts_at, "cannot be in the past") if starts_at < Time.current
  end

  def starts_at_cannot_move_to_past
    return if starts_at.blank?

    errors.add(:starts_at, "cannot be in the past") if starts_at < Time.current
  end

  def no_employee_overlap
    overlap = self.class.overlapping(starts_at, ends_at, excluding_id: id).where(user_id: user_id)
    return unless overlap.exists?

    errors.add(:starts_at, "conflicts with another meeting for this employee")
  end

  def no_calendar_overlap
    overlap = self.class.overlapping(starts_at, ends_at, excluding_id: id)
    return unless overlap.exists?

    errors.add(:starts_at, "conflicts with another meeting on the company calendar")
  end
end
