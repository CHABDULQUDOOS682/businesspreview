class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "devdebizz@gmail.com")
  layout "mailer"
  helper :application

  before_action :attach_logo

  private

  def attach_logo
    logo_path = Rails.root.join("public/icon.png")
    if File.exist?(logo_path)
      attachments.inline["logo.png"] = File.read(logo_path)
    end
  end
end
