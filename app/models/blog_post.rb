class BlogPost < ApplicationRecord
  FEATURED_IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp image/gif].freeze
  FEATURED_IMAGE_MAX_BYTES = 5.megabytes

  has_rich_text :body
  has_one_attached :featured_image

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true
  validates :excerpt, presence: true
  validate :featured_image_constraints

  before_validation :ensure_slug

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(Arel.sql("published_on DESC NULLS LAST"), created_at: :desc) }
  scope :published, -> { active.ordered }

  def readable?
    body.to_plain_text.to_s.strip.present?
  end

  def display_date
    published_on&.strftime("%B %-d, %Y") || created_at.strftime("%B %-d, %Y")
  end

  def display_read_time
    read_time_label.presence || "5 min read"
  end

  private

  def ensure_slug
    self.slug = title.to_s.parameterize if slug.blank? && title.present?
  end

  def featured_image_constraints
    return unless featured_image.attached?

    unless featured_image.content_type.in?(FEATURED_IMAGE_CONTENT_TYPES)
      errors.add(:featured_image, "must be PNG, JPG, WEBP, or GIF")
    end

    if featured_image.byte_size > FEATURED_IMAGE_MAX_BYTES
      errors.add(:featured_image, "must be smaller than 5 MB")
    end
  end
end
