class ApplicationMailer < ActionMailer::Base
  default from: "noreply@devdebizz.com"
  layout "mailer"
  helper :application

  before_action :attach_logo

  private

  LOGO_CANDIDATES = [
    "public/brand/logo.png",
    "app/assets/images/logo/Website Logo PNG.png",
    "public/icon.png"
  ].freeze

  def attach_logo
    logo_path = LOGO_CANDIDATES
      .map { |relative| Rails.root.join(relative) }
      .find { |path| File.exist?(path) }

    return if logo_path.blank?

    attachments.inline["logo.png"] = File.read(logo_path)
  end
end
