class Review < ApplicationRecord
  belongs_to :business, optional: true
  validates :client_name, :content, presence: true
  validates :rating, inclusion: { in: 1..5 }
  scope :active, -> { where(active: true) }
end
