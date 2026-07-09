class Feedback < ApplicationRecord
  FEEDBACK_TYPES = %w[bug feature_request improvement ui_ux performance documentation general].freeze
  PRIORITIES = %w[low medium high critical].freeze
  STATUSES = %w[pending under_review approved rejected planned in_progress testing completed closed].freeze
  RESOLVED_STATUSES = %w[completed closed].freeze
  MAX_SCREENSHOTS = 5
  SCREENSHOT_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp image/gif].freeze

  belongs_to :user

  has_many_attached :screenshots

  enum :feedback_type, FEEDBACK_TYPES.index_by(&:itself), validate: true
  enum :priority, PRIORITIES.index_by(&:itself), validate: true, default: :medium
  enum :status, STATUSES.index_by(&:itself), validate: true, default: :pending

  validates :title, :description, :feedback_type, presence: true
  validates :title, length: { maximum: 255 }
  validates :feedback_type, inclusion: { in: FEEDBACK_TYPES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }
  validate :reject_blank_submission
  validate :bug_fields_present, if: :bug?
  validate :screenshot_limits

  scope :for_user, ->(user) { where(user: user) }
  scope :bugs, -> { where(feedback_type: "bug") }
  scope :feature_requests, -> { where(feedback_type: "feature_request") }
  scope :critical_priority, -> { where(priority: "critical") }
  scope :recent_first, -> { order(created_at: :desc) }

  def editable_by?(actor)
    return false if actor.blank?
    return true if actor.role_super_admin?
    return true if actor.role_admin?
    actor.id == user_id && pending?
  end

  def deletable_by?(actor)
    actor&.role_super_admin?
  end

  def manageable_by?(actor)
    return false if actor.blank?

    actor.role_super_admin? || actor.role_admin?
  end

  def resolved?
    RESOLVED_STATUSES.include?(status)
  end

  private

  def reject_blank_submission
    %i[title description].each do |attribute|
      value = public_send(attribute)
      errors.add(attribute, "can't be blank") if value.present? && value.strip.blank?
    end
  end

  def bug_fields_present
    %i[steps_to_reproduce expected_result actual_result].each do |attribute|
      value = public_send(attribute).to_s.strip
      errors.add(attribute, "can't be blank for bug reports") if value.blank?
    end
  end

  def screenshot_limits
    return unless screenshots.attached?

    if screenshots.count > MAX_SCREENSHOTS
      errors.add(:screenshots, "cannot exceed #{MAX_SCREENSHOTS} files")
    end

    screenshots.each do |screenshot|
      next if screenshot.content_type.in?(SCREENSHOT_CONTENT_TYPES)

      errors.add(:screenshots, "must be PNG, JPG, WEBP, or GIF")
      break
    end
  end
end
