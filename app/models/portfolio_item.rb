class PortfolioItem < ApplicationRecord
  ACCENT_COLORS = [
    "from-[#213885]/30",
    "from-emerald-400/30",
    "from-cyan-400/30",
    "from-amber-300/30",
    "from-rose-400/30",
    "from-violet-400/30"
  ].freeze

  validates :title, :category, presence: true
  validates :description, presence: true
  validates :accent_color, inclusion: { in: ACCENT_COLORS }, allow_blank: true

  before_validation :assign_default_position, on: :create

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
end
