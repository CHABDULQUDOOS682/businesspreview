# config/environments/staging.rb

require_relative "production"

Rails.application.configure do
  # ----------------------------
  # Staging overrides only
  # ----------------------------

  # Show errors in staging (VERY important for debugging)
  config.consider_all_requests_local = true

  # More logs for debugging
  config.log_level = :debug

  # Safer for testing (avoid real cached responses hiding bugs)
  config.action_controller.perform_caching = false

  # Safer email behavior in staging (don’t fail deploys due to SMTP)
  config.action_mailer.raise_delivery_errors = false

  # Optional: disable SSL enforcement in staging if needed for local/dev testing
  # config.force_ssl = false
end
