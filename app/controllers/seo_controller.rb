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
    if Rails.env.staging?
      return <<~ROBOTS
        User-agent: *
        Disallow: /
      ROBOTS
    end

    host = ENV.fetch("APP_HOST", request.host)
    protocol = ENV.fetch("APP_PROTOCOL", "https")

    <<~ROBOTS
      User-agent: *
      Allow: /
      Disallow: /admin
      Disallow: /users
      Disallow: /lp/
      Disallow: /pay/
      Disallow: /reviews/new/
      Disallow: /schedule/confirmation/
      Disallow: /schedule/slots
      Disallow: /twilio/
      Disallow: /webhooks/
      Disallow: /rails/
      Disallow: /up

      Sitemap: #{protocol}://#{host}/sitemap.xml
    ROBOTS
  end

  def sitemap_urls
    urls = [
      { loc: root_url, changefreq: "weekly", priority: "1.0" },
      { loc: services_url, changefreq: "monthly", priority: "0.9" },
      { loc: about_url, changefreq: "monthly", priority: "0.8" },
      { loc: process_url, changefreq: "monthly", priority: "0.8" },
      { loc: pricing_url, changefreq: "weekly", priority: "0.9" },
      { loc: portfolio_url, changefreq: "weekly", priority: "0.8" },
      { loc: contact_url, changefreq: "monthly", priority: "0.7" },
      { loc: blog_url, changefreq: "weekly", priority: "0.8" },
      { loc: schedule_url, changefreq: "monthly", priority: "0.7" },
      { loc: careers_url, changefreq: "monthly", priority: "0.4" },
      { loc: press_url, changefreq: "monthly", priority: "0.4" },
      { loc: partners_url, changefreq: "monthly", priority: "0.4" },
      { loc: help_center_url, changefreq: "monthly", priority: "0.4" },
      { loc: documentation_url, changefreq: "monthly", priority: "0.4" },
      { loc: brand_kit_url, changefreq: "monthly", priority: "0.3" },
      { loc: privacy_url, changefreq: "yearly", priority: "0.2" },
      { loc: terms_url, changefreq: "yearly", priority: "0.2" },
      { loc: cookie_policy_url, changefreq: "yearly", priority: "0.2" },
      { loc: gdpr_url, changefreq: "yearly", priority: "0.2" },
      { loc: accessibility_url, changefreq: "yearly", priority: "0.2" }
    ]

    BlogPost.published.find_each do |post|
      next unless post.readable?

      urls << {
        loc: blog_post_url(post.slug),
        lastmod: post.updated_at,
        changefreq: "monthly",
        priority: "0.6"
      }
    end

    urls
  end
end
