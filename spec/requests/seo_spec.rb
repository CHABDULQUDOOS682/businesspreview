require "rails_helper"

RSpec.describe "Seo", type: :request do
  describe "GET /robots.txt" do
    it "allows marketing pages and points to the sitemap" do
      get robots_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to include("Disallow: /admin")
      expect(response.body).to include("Disallow: /lp/")
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

      get sitemap_path

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("application/xml")
      expect(response.body).to include(root_url)
      expect(response.body).to include(services_url)
      expect(response.body).to include(portfolio_url)
      expect(response.body).to include(blog_url)
      expect(response.body).to include(blog_post_url("readable-post"))
      expect(response.body).not_to include(blog_post_url("coming-soon-card"))
      expect(response.body).not_to include("/lp/")
      expect(response.body).not_to include("/admin")
    end
  end
end
