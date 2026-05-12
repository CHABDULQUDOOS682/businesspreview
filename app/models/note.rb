class Note < ApplicationRecord
  belongs_to :business

  validates :body, presence: true
end
