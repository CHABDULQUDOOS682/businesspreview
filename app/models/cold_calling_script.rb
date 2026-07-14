class ColdCallingScript < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_rich_text :body

  validates :title, presence: true
  validates :body, presence: true

  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) {
    category.present? ? where(category: category) : all
  }
  scope :alphabetical, -> { order(:category, :title) }
  scope :with_rich_body, -> { with_rich_text_body }
end
