require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Staging is production-like and is intended for Render.
  # Keep it close to production so deploy issues appear before release.

  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  config.active_storage.service = :local

  config.assume_ssl = true
  config.force_ssl = true

  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  config.cache_store = :solid_cache_store

  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST"),
    protocol: ENV.fetch("APP_PROTOCOL", "https")
  }

  smtp_port = ENV.fetch("SMTP_PORT", 587).to_i
  smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: smtp_port,
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    domain: ENV.fetch("APP_HOST"),
    authentication: :plain,
    openssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
  }

  if smtp_port == 465
    smtp_settings[:ssl] = true
    smtp_settings[:tls] = true
  else
    smtp_settings[:enable_starttls_auto] = true
  end

  config.action_mailer.smtp_settings = smtp_settings.compact

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  config.require_master_key = true

  if ENV["APP_HOSTS"].present?
    config.hosts.concat(ENV["APP_HOSTS"].split(",").map(&:strip))
  end
end
