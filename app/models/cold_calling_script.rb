class ColdCallingScript < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  validates :title, :body, presence: true

  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) {
    category.present? ? where(category: category) : all
  }
  scope :alphabetical, -> { order(:category, :title) }
end
