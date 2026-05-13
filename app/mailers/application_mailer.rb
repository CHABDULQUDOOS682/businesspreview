class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "hello@devdebizz.com")
  layout "mailer"
end
