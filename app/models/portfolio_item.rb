class PortfolioItem < ApplicationRecord
  ACCENT_COLORS = [
    "from-[#213885]/30",
    "from-emerald-400/30",
    "from-cyan-400/30",
    "from-amber-300/30",
    "from-rose-400/30",
    "from-violet-400/30"
  ].freeze
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp image/gif].freeze
  IMAGE_MAX_BYTES = 5.megabytes

  has_one_attached :image

  validates :title, :category, presence: true
  validates :description, presence: true
  validates :accent_color, inclusion: { in: ACCENT_COLORS }, allow_blank: true
  validates :link_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid http(s) URL" }, allow_blank: true
  validate :image_constraints

  before_validation :assign_default_position, on: :create
  before_validation :normalize_link_url

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
  scope :published, -> { active.ordered }

  def initials
    title.to_s.split.map { |word| word.first }.join.first(2).upcase
  end

  private

  def assign_default_position
    return if position.present? && position != 0

    self.position = (self.class.maximum(:position) || 0) + 1
  end

  def normalize_link_url
    self.link_url = link_url.to_s.strip.presence
  end

  def image_constraints
    return unless image.attached?

    unless image.content_type.in?(IMAGE_CONTENT_TYPES)
      errors.add(:image, "must be PNG, JPG, WEBP, or GIF")
    end

    if image.byte_size > IMAGE_MAX_BYTES
      errors.add(:image, "must be smaller than 5 MB")
    end
  end
end
