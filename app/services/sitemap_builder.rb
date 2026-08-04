# frozen_string_literal: true

# Builds the public marketing sitemap for preview_app.
# Keep this aligned with HomePagesHelper marketing nav + footer columns.
class SitemapBuilder
  include Rails.application.routes.url_helpers

  def initialize(default_url_options: Rails.application.routes.default_url_options)
    @default_url_options = default_url_options
  end

  def call
    blog_entries, blog_lastmod = blog_post_entries
    portfolio_lastmod = PortfolioItem.published.maximum(:updated_at)

    primary_pages(blog_lastmod:, portfolio_lastmod:) +
      service_pages +
      resource_pages +
      legal_pages +
      blog_entries
  end

  private

  attr_reader :default_url_options

  def primary_pages(blog_lastmod:, portfolio_lastmod:)
    [
      entry(root_url, changefreq: "weekly", priority: "1.0"),
      entry(services_url, changefreq: "monthly", priority: "0.9"),
      entry(about_url, changefreq: "monthly", priority: "0.8"),
      entry(process_url, changefreq: "monthly", priority: "0.8"),
      entry(portfolio_url, changefreq: "weekly", priority: "0.85", lastmod: portfolio_lastmod),
      entry(pricing_url, changefreq: "weekly", priority: "0.9"),
      entry(blog_url, changefreq: "weekly", priority: "0.85", lastmod: blog_lastmod),
      entry(contact_url, changefreq: "monthly", priority: "0.8"),
      entry(schedule_url, changefreq: "monthly", priority: "0.7")
    ]
  end

  def service_pages
    [
      entry(website_design_url, changefreq: "monthly", priority: "0.85"),
      entry(seo_url, changefreq: "monthly", priority: "0.85"),
      entry(booking_systems_url, changefreq: "monthly", priority: "0.85"),
      entry(follow_up_systems_url, changefreq: "monthly", priority: "0.85")
    ]
  end

  def resource_pages
    [
      entry(careers_url, changefreq: "monthly", priority: "0.4"),
      entry(press_url, changefreq: "monthly", priority: "0.4"),
      entry(partners_url, changefreq: "monthly", priority: "0.4"),
      entry(help_center_url, changefreq: "monthly", priority: "0.5"),
      entry(documentation_url, changefreq: "monthly", priority: "0.4"),
      entry(brand_kit_url, changefreq: "yearly", priority: "0.3")
    ]
  end

  def legal_pages
    [
      entry(privacy_url, changefreq: "yearly", priority: "0.2"),
      entry(terms_url, changefreq: "yearly", priority: "0.2"),
      entry(cookie_policy_url, changefreq: "yearly", priority: "0.2"),
      entry(gdpr_url, changefreq: "yearly", priority: "0.2"),
      entry(accessibility_url, changefreq: "yearly", priority: "0.2")
    ]
  end

  def blog_post_entries
    entries = []
    latest = nil

    BlogPost.published.with_rich_text_body.find_each do |post|
      next unless post.readable?

      latest = [ latest, post.updated_at ].compact.max
      entries << entry(
        blog_post_url(post.slug),
        changefreq: "monthly",
        priority: "0.65",
        lastmod: post.updated_at
      )
    end

    [ entries, latest ]
  end

  def entry(loc, changefreq:, priority:, lastmod: nil)
    {
      loc: loc,
      changefreq: changefreq,
      priority: priority,
      lastmod: normalize_lastmod(lastmod)
    }.compact
  end

  def normalize_lastmod(value)
    return if value.blank?
    return value.utc if value.respond_to?(:utc)
    return value.to_time.utc if value.respond_to?(:to_time)

    value
  end
end
