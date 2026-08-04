require "rails_helper"

RSpec.describe "Seo", type: :request do
  describe "GET /robots.txt" do
    it "allows marketing pages and points to the sitemap" do
      get robots_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to include("Allow: /")
      expect(response.body).to include("Disallow: /admin")
      expect(response.body).to include("Disallow: /users")
      expect(response.body).to include("Disallow: /lp/")
      expect(response.body).to include("Disallow: /pay/")
      expect(response.body).to include("Disallow: /reviews/")
      expect(response.body).to include("Disallow: /landing_pages/")
      expect(response.body).to include("Disallow: /schedule/confirmation/")
      expect(response.body).to include("Disallow: /schedule/slots")
      expect(response.body).to include("Disallow: /twilio/")
      expect(response.body).to include("Disallow: /webhooks/")
      expect(response.body).to include("Disallow: /rails/")
      expect(response.body).to include("Disallow: /up")
      expect(response.body).to include("Disallow: /service-worker.js")
      expect(response.body).to include("Disallow: /design_1")
      expect(response.body).to include("Disallow: /abc")
      expect(response.body).to include("Sitemap:")
      expect(response.body).to include("/sitemap.xml")
    end

    it "disallows everything in staging" do
      host! "example.com"
      allow(Rails.env).to receive(:staging?).and_return(true)

      get robots_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Disallow: /")
      expect(response.body).not_to include("Sitemap:")
    end
  end

  describe "GET /sitemap.xml" do
    it "includes core marketing URLs and readable blog posts" do
      post = create(:blog_post, title: "Readable post", slug: "readable-post", active: true)
      post.update!(body: "<p>Published body</p>")
      create(:blog_post, title: "Coming soon card", slug: "coming-soon-card", active: true)
      create(:portfolio_item, title: "Sample shop", active: true)

      get sitemap_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/xml")
      expect(response.body).to include(root_url)
      expect(response.body).to include(services_url)
      expect(response.body).to include(about_url)
      expect(response.body).to include(process_url)
      expect(response.body).to include(website_design_url)
      expect(response.body).to include(seo_url)
      expect(response.body).to include(booking_systems_url)
      expect(response.body).to include(follow_up_systems_url)
      expect(response.body).to include(portfolio_url)
      expect(response.body).to include(pricing_url)
      expect(response.body).to include(blog_url)
      expect(response.body).to include(contact_url)
      expect(response.body).to include(schedule_url)
      expect(response.body).to include(blog_post_url("readable-post"))
      expect(response.body).not_to include(blog_post_url("coming-soon-card"))
      expect(response.body).not_to include("/lp/")
      expect(response.body).not_to include("/admin")
      expect(response.body).not_to include(design_1_url)
      expect(response.body).not_to include(abc_url)
      expect(response.body).to include("<lastmod>")
    end

    it "includes every marketed legal and resource URL" do
      get sitemap_path

      expect(response.body).to include(help_center_url)
      expect(response.body).to include(documentation_url)
      expect(response.body).to include(brand_kit_url)
      expect(response.body).to include(press_url)
      expect(response.body).to include(partners_url)
      expect(response.body).to include(careers_url)
      expect(response.body).to include(privacy_url)
      expect(response.body).to include(terms_url)
      expect(response.body).to include(cookie_policy_url)
      expect(response.body).to include(gdpr_url)
      expect(response.body).to include(accessibility_url)
    end
  end
end
