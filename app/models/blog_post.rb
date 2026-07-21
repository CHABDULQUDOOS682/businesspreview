class BlogPost < ApplicationRecord
  has_rich_text :body

  validates :title, :slug, presence: true
  validates :slug, uniqueness: true
  validates :excerpt, presence: true

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
end
