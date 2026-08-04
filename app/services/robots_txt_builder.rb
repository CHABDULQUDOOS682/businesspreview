# frozen_string_literal: true

# Builds /robots.txt for preview_app.
# Keep Disallow paths aligned with SitemapBuilder exclusions and non-marketing routes.
class RobotsTxtBuilder
  STAGING_BODY = <<~ROBOTS
    User-agent: *
    Disallow: /
  ROBOTS

  # Paths crawlers should skip (CRM, tokens, stubs, infra).
  DISALLOWED_PATHS = [
    "/admin",
    "/users",
    "/lp/",
    "/pay/",
    "/reviews/",
    "/landing_pages/",
    "/schedule/confirmation/",
    "/schedule/slots",
    "/twilio/",
    "/webhooks/",
    "/rails/",
    "/up",
    "/service-worker.js",
    "/design_1",
    "/abc"
  ].freeze

  def initialize(host:, protocol:, staging: Rails.env.staging?)
    @host = host
    @protocol = protocol
    @staging = staging
  end

  def call
    return STAGING_BODY if staging?

    <<~ROBOTS
      # DevDeBizz marketing site — crawl public pages; skip CRM and tokenized links.
      User-agent: *
      Allow: /

      #{disallow_lines}

      Sitemap: #{protocol}://#{host}/sitemap.xml
    ROBOTS
  end

  private

  attr_reader :host, :protocol

  def staging?
    @staging
  end

  def disallow_lines
    DISALLOWED_PATHS.map { |path| "Disallow: #{path}" }.join("\n")
  end
end
