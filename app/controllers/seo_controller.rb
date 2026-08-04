class SeoController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection

  def robots
    render plain: robots_body, content_type: "text/plain"
  end

  def sitemap
    @urls = sitemap_urls
    render formats: :xml
  end

  private

  # Always allow crawlers / older UAs to fetch robots + sitemap.
  def enforce_modern_browser?
    false
  end

  def robots_body
    RobotsTxtBuilder.new(
      host: ENV.fetch("APP_HOST", request.host),
      protocol: ENV.fetch("APP_PROTOCOL", "https"),
      staging: Rails.env.staging?
    ).call
  end

  def sitemap_urls
    SitemapBuilder.new(default_url_options: sitemap_url_options).call
  end

  # Prefer the current request host so local/test/staging previews stay accurate.
  # Production still gets https via APP_PROTOCOL when set on routes.default_url_options.
  def sitemap_url_options
    route_defaults = Rails.application.routes.default_url_options || {}

    {
      host: request.host,
      protocol: route_defaults[:protocol].presence || (request.ssl? ? "https" : "http")
    }
  end
end
