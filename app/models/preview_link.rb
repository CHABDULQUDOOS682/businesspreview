class PreviewLink < ApplicationRecord
  belongs_to :business

  before_validation :generate_uuid, on: :create

  def self.available_templates
    Dir.children(Rails.root.join("app/views/templates"))
       .map { |f| f.split(".").first }
  end

  validates :template, inclusion: { in: ->(_) { available_templates } }

  private

  def generate_uuid
    self.uuid ||= SecureRandom.hex(6)
  end
end
