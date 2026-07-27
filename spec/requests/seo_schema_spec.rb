require "rails_helper"

RSpec.describe "Marketing SEO meta and schema", type: :request do
  describe "meta descriptions" do
    it "serves unique persuasive descriptions on high-priority pages" do
      {
        root_path => "Book a discovery call for your service business",
        services_path => "Get a free quote",
        about_path => "growth studio for service businesses",
        process_path => "Discover, Design, Build, Grow",
        portfolio_path => "barbershops, salons, clinics",
        pricing_path => "no hidden fees",
        contact_path => "We reply within one business day",
        blog_path => "from the DevDeBizz team",
        website_design_path => "Custom website design for service businesses"
      }.each do |path, snippet|
        get path
        expect(response).to have_http_status(:success), path
        expect(response.body).to include(%(name="description" content="))
        expect(response.body).to include(snippet), "#{path} missing #{snippet}"
        expect(response.body).to include(%(property="og:description"))
        expect(response.body).not_to include("Cloud &amp; DevOps")
        expect(response.body).not_to include("Performance Marketing")
        expect(response.body).not_to include("fintech")
      end
    end
  end

  describe "JSON-LD structured data" do
    it "includes Organization schema on marketing pages" do
      get root_path

      expect(response.body).to include('type="application/ld+json"')
      expect(response.body).to include('"@type":"Organization"')
      expect(response.body).to include("/brand/logo.png")
      expect(response.body).to include('"telephone":"+14064792002"')
    end

    it "includes LocalBusiness schema on home and contact" do
      [ root_path, contact_path ].each do |path|
        get path
        expect(response.body).to include('"@type":"ProfessionalService"')
        expect(response.body).to include("Kalispell")
        expect(response.body).to include('"opens":"09:00"')
      end
    end

    it "shows matching business hours on the contact page" do
      get contact_path
      expect(response.body).to include("Mon–Fri · 9:00 AM–5:00 PM MT")
    end

    it "includes Service catalog schema on services pages" do
      get services_path

      expect(response.body).to include('"@type":"Service"')
      expect(response.body).to include("Website Design")
      expect(response.body).to include("Follow-Up Systems")
      expect(response.body).not_to include("Cloud & DevOps")
    end

    it "includes BreadcrumbList on inner pages" do
      get about_path

      expect(response.body).to include('"@type":"BreadcrumbList"')
      expect(response.body).to include('"name":"About"')
    end

    it "includes Article schema on readable blog posts" do
      post = create(:blog_post, title: "Mobile homepage tips", slug: "mobile-homepage-tips", active: true, published_on: Date.new(2026, 6, 15))
      post.update!(body: "<p>Useful mobile tips.</p>", excerpt: "Mobile tips excerpt")

      get blog_post_path(post.slug)

      expect(response.body).to include('"@type":"Article"')
      expect(response.body).to include("Mobile homepage tips")
      expect(response.body).to include("2026-06-15")
    end

    it "includes FAQPage schema on the help center" do
      get help_center_path

      expect(response.body).to include('"@type":"FAQPage"')
      expect(response.body).to include("How long does a website project take?")
      expect(response.body).to include("We start planning in the first week")
    end
  end
end
