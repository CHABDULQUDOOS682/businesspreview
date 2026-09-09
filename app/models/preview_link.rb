class PreviewLink < ApplicationRecord
  belongs_to :business

  before_validation :generate_uuid, on: :create

  def self.available_templates
    base_path = Rails.root.join("app/views/templates")

    Dir.glob(base_path.join("**/*.html.erb")).map do |file|
      Pathname.new(file)
              .relative_path_from(base_path)
              .to_s
              .sub(".html.erb", "")
    end
  end

  validates :template, inclusion: { in: ->(_) { available_templates } }

  private

  # 48 bits was brute-forceable; these URLs are public and unauthenticated.
  def generate_uuid
    self.uuid ||= SecureRandom.hex(16)
  end
end
