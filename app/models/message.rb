class Message < ApplicationRecord
  belongs_to :business, optional: true

  validates :from_number, presence: true
  validates :to_number, presence: true
  validates :body, presence: true
  validates :direction, inclusion: { in: %w[inbound outbound] }

  before_save :normalize_numbers

  scope :inbound, -> { where(direction: "inbound") }
  scope :outbound, -> { where(direction: "outbound") }

  private

  def normalize_numbers
    self.from_number = from_number.to_s.gsub(/\s+/, "")
    self.to_number = to_number.to_s.gsub(/\s+/, "")
  end
end
