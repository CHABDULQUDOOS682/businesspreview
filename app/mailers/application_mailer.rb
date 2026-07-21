class ApplicationMailer < ActionMailer::Base
  default from: "noreply@devdebizz.com"
  layout "mailer"
  helper :application

  before_action :attach_logo

  private

  LOGO_SVG_CANDIDATES = [
    "public/brand/logo.svg",
    "app/assets/images/logo/Website Icon logo SVG 512x512.svg",
    "app/assets/images/logo/Normal Icon SVG.svg"
  ].freeze

  def attach_logo
    logo_path = LOGO_SVG_CANDIDATES
      .map { |relative| Rails.root.join(relative) }
      .find { |path| File.exist?(path) }

    return if logo_path.blank?

    attachments.inline["logo.svg"] = {
      mime_type: "image/svg+xml",
      content: File.read(logo_path)
    }
  end
end
