class Note < ApplicationRecord
  belongs_to :business
  belongs_to :user, optional: true

  validates :body, presence: true

  def creator_name
    user&.display_name || "System"
  end

  def creator_role
    user&.role&.to_s&.humanize || "System"
  end
end
