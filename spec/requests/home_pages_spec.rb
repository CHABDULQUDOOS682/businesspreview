require 'rails_helper'

RSpec.describe "HomePages", type: :request do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "uses a keyword-rich home title and avoids filler local SEO language" do
      get root_path

      expect(response.body).to include("DevDeBizz | Web Design &amp; SEO Agency for Service Businesses")
      expect(response.body).to include("search visibility")
      expect(response.body).not_to include("local SEO")
      expect(response.body).not_to include("Websites and systems that convert")
    end

    it "frames week-one planning instead of a conflicting 7-day launch promise" do
      get root_path

      expect(response.body).to include("Week 1")
      expect(response.body).to include("Planning kickoff")
      expect(response.body).not_to include("7-day")
    end

    it "uses the shared discovery-call CTA and avoids forbidden stack claims" do
      get root_path

      expect(response.body).to include("Book a discovery call")
      expect(response.body).to include(schedule_path)
      expect(response.body).not_to include("Start a Project")
      expect(response.body).not_to include("React")
      expect(response.body).not_to include("Next.js")
      expect(response.body).to include('property="og:image"')
      expect(response.body).to match(%r{og:image" content="[^"]*Website Logo PNG[^"]*\.png"})
      expect(response.body).to include('rel="canonical"')
      expect(response.body).to include("/favicon-32x32.png")
      expect(response.body).to include("/apple-touch-icon.png")
      expect(response.body).not_to include('fill="red"')
    end

    it "does not show a reviews placeholder when no reviews exist" do
      get root_path

      expect(response.body).not_to include("Reviews will appear here once approved")
      expect(response.body).not_to include("What our partners say")
    end

    it "renders active reviews when present" do
      create(:review, client_name: "Maria G.", content: "Saved our hardwoods.", active: true)

      get root_path

      expect(response.body).to include("What our partners say")
      expect(response.body).to include("Maria G.")
      expect(response.body).to include("Saved our hardwoods.")
    end
  end

  describe "GET /about" do
    it "returns http success" do
      get about_path
      expect(response).to have_http_status(:success)
    end

    it "positions the studio around service businesses" do
      get about_path

      expect(response.body).to include("growth-minded service businesses")
      expect(response.body).to include("Customer-first thinking")
      expect(response.body).not_to include("growth-minded local brands")
      expect(response.body).not_to include("Local-first thinking")
    end
  end

  describe "GET /services" do
    it "returns http success" do
      get services_path
      expect(response).to have_http_status(:success)
    end

    it "uses search-visibility language instead of local SEO filler" do
      get services_path

      expect(response.body).to include("search visibility")
      expect(response.body).to include("Service-page SEO structure")
      expect(response.body).not_to include("Local SEO structure")
      expect(response.body).not_to include("local SEO setup")
    end

    it "links the hub cards to dedicated service pages" do
      get services_path

      expect(response.body).to include(website_design_path)
      expect(response.body).to include(seo_path)
      expect(response.body).to include(booking_systems_path)
      expect(response.body).to include(follow_up_systems_path)
    end
  end

  describe "GET /website-design" do
    it "returns a dedicated website design page" do
      get website_design_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Website Design for Service Businesses")
      expect(response.body).to include("More booked conversations")
    end
  end

  describe "GET /seo" do
    it "returns a dedicated SEO page" do
      get seo_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("SEO for Service Businesses")
      expect(response.body).to include("Found for the searches that matter")
    end
  end

  describe "GET /booking-systems" do
    it "returns a dedicated booking systems page" do
      get booking_systems_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Booking Systems for Service Businesses")
      expect(response.body).to include("Fewer dropped inquiries")
    end
  end

  describe "GET /follow-up-systems" do
    it "returns a dedicated follow-up systems page" do
      get follow_up_systems_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Follow-Up &amp; CRM Systems for Service Businesses")
      expect(response.body).to include("Fewer cold leads")
    end
  end

  describe "GET /workflow" do
    it "returns http success and renders process" do
      get process_path
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:process)
    end

    it "shows shared timeline framing and early SEO detail" do
      get process_path

      expect(response.body).to include("How long projects usually take")
      expect(response.body).to include("2–3 days")
      expect(response.body).to include("4–6 days")
      expect(response.body).to include("according to app size")
      expect(response.body).to include("Keyword targeting")
      expect(response.body).to include("metadata are planned before build")
    end
  end

  describe "GET /help_center" do
    it "returns http success" do
      get help_center_path
      expect(response).to have_http_status(:success)
    end

    it "uses the shared timeline framing instead of a conflicting 3–4 week claim" do
      get help_center_path

      expect(response.body).to include("We start planning in the first week")
      expect(response.body).to include("2–3 days")
      expect(response.body).not_to include("3 to 4 weeks from scope approval")
    end
  end

  describe "GET /pricing" do
    it "returns http success" do
      get pricing_path
      expect(response).to have_http_status(:success)
    end

    it "renders subscription and project pricing content" do
      get pricing_path

      expect(response.body).to include("Subscription")
      expect(response.body).to include("Essential")
      expect(response.body).to include("$30")
      expect(response.body).to include("One-time setup fee: $99")
      expect(response.body).to include("One-time setup fee: $199")
      expect(response.body).to include("One-time setup fee: $299")
      expect(response.body).to include("Hot Selling")
      expect(response.body).to include("Project")
      expect(response.body).to include("Starter Website")
      expect(response.body).to include("$199")
      expect(response.body).to include("$299")
      expect(response.body).to include("Custom quote")
      expect(response.body).to include("Based on features &amp; complexity")
      expect(response.body).not_to include("Retainer")
      expect(response.body).not_to include("DevOps & CI/CD")
      expect(response.body).to include("Custom Rails web application development")
      expect(response.body).to include("Website design")
      expect(response.body).to include(website_design_path)
      expect(response.body).to include(careers_path)
      expect(response.body).to include("Week-one planning")
      expect(response.body).to include("We start planning in the first week")
    end
  end

  describe "GET /portfolio" do
    it "returns http success" do
      get portfolio_path
      expect(response).to have_http_status(:success)
    end

    it "renders active portfolio items from the database" do
      create(:portfolio_item, title: "Barbershop Website Redesign: More Chair Bookings", active: true)
      create(:portfolio_item, title: "Hidden Build", active: false)

      get portfolio_path

      expect(response.body).to include("Barbershop Website Redesign: More Chair Bookings")
      expect(response.body).not_to include("Hidden Build")
      expect(response.body).not_to include("Norvik Apparel")
      expect(response.body).not_to include("PulseMetric")
      expect(response.body).not_to include("Kavari Pay")
    end

    it "uses niche empty-state copy when no published items exist" do
      get portfolio_path

      expect(response.body).to include("Want to see builds for your industry?")
      expect(response.body).to include("Book a discovery call")
      expect(response.body).not_to include("Portfolio launching soon")
    end

    it "renders project image and link when present" do
      item = create(
        :portfolio_item,
        title: "Linked Salon",
        link_url: "https://example.com/salon",
        active: true
      )
      item.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/blog_feature.png")),
        filename: "blog_feature.png",
        content_type: "image/png"
      )

      get portfolio_path

      expect(response.body).to include("Linked Salon")
      expect(response.body).to include("View project")
      expect(response.body).to include("https://example.com/salon")
      expect(response.body).to include("blog_feature")
    end
  end

  describe "GET /blog" do
    it "returns http success" do
      get blog_path
      expect(response).to have_http_status(:success)
    end

    it "renders active blog posts and coming soon when body is blank" do
      create(:blog_post, title: "Mobile homepage tips", active: true)

      get blog_path

      expect(response.body).to include("Mobile homepage tips")
      expect(response.body).to include("Coming soon")
      expect(response.body).not_to include("Read UX Guide")
    end
  end

  describe "GET /blog/:slug" do
    it "shows a readable published post" do
      post = create(:blog_post, title: "Follow-up systems", slug: "follow-up-systems", active: true)
      post.update!(body: "<p>Write the sequence within five minutes.</p>")

      get blog_post_path(post.slug)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Follow-up systems")
      expect(response.body).to include("Write the sequence within five minutes.")
      expect(response.body).to match(/Back to blog[\s\S]*Follow-up systems/)
    end

    it "shows the feature image when attached" do
      post = create(:blog_post, title: "Image post", slug: "image-post", active: true)
      post.update!(body: "<p>Body copy.</p>")
      post.featured_image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/blog_feature.png")),
        filename: "blog_feature.png",
        content_type: "image/png"
      )

      get blog_post_path(post.slug)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("blog_feature")
    end

    it "returns not found for coming soon cards without body" do
      post = create(:blog_post, title: "Draft card", slug: "draft-card", active: true)

      get blog_post_path(post.slug)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /contact" do
    it "returns http success" do
      get contact_path
      expect(response).to have_http_status(:success)
    end

    it "shows the contact email helper and omits placeholder phone" do
      get contact_path

      expect(response.body).to include(ENV.fetch("CONTACT_EMAIL", "team@devdebizz.com"))
      expect(response.body).to include("+1 (406) 479-2002")
      expect(response.body).to include("tel:+14064792002")
      expect(response.body).not_to include(">NA<")
      expect(response.body).not_to include("tel:+111111111")
      expect(response.body).not_to include("Cloud & DevOps")
      expect(response.body).not_to include("Performance Marketing")
      expect(response.body).to include("Website builds")
      expect(response.body).to include("Custom Rails application")
    end

    it "shows phone when CONTACT_PHONE is configured" do
      previous = ENV["CONTACT_PHONE"]
      ENV["CONTACT_PHONE"] = "(713) 555-0101"

      get contact_path

      expect(response.body).to include("(713) 555-0101")
      expect(response.body).to include("tel:7135550101")
    ensure
      if previous.nil?
        ENV.delete("CONTACT_PHONE")
      else
        ENV["CONTACT_PHONE"] = previous
      end
    end
  end

  describe "POST /contact" do
    it "queues a lead alert email and redirects with a notice" do
      mailer = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      expect(ContactMailer).to receive(:new_lead_alert).and_return(mailer)

      post contact_submissions_path, params: {
        first_name: "Jane",
        last_name: "Doe",
        email: "jane@example.com",
        company: "Acme",
        service_interest: "Website",
        message: "Hello"
      }

      expect(response).to redirect_to(contact_path)
      expect(flash[:notice]).to include("inquiry was sent successfully")
    end
  end

  describe "GET /privacy" do
    it "returns http success" do
      get privacy_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /careers" do
    it "returns http success" do
      get careers_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /press" do
    it "returns http success" do
      get press_path
      expect(response).to have_http_status(:success)
    end

    it "uses a fixed founded year and links to the brand kit" do
      get press_path

      expect(response.body).to include("2024")
      expect(response.body).to include(brand_kit_path)
      expect(response.body).not_to include('href="#"')
    end
  end

  describe "GET /partners" do
    it "returns http success" do
      get partners_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /documentation" do
    it "returns http success" do
      get documentation_path
      expect(response).to have_http_status(:success)
    end

    it "links to help center and contact instead of dead anchors" do
      get documentation_path

      expect(response.body).to include(help_center_path)
      expect(response.body).to include(contact_path)
      expect(response.body).not_to include('href="#"')
    end
  end

  describe "GET /brand_kit" do
    it "returns http success" do
      get brand_kit_path
      expect(response).to have_http_status(:success)
    end

    it "offers real SVG asset downloads" do
      get brand_kit_path

      expect(response.body).to include("Download SVG")
      expect(response.body).to include("logo/")
      expect(response.body).not_to include('href="#"')
    end
  end

  describe "GET /cookie_policy" do
    it "returns http success" do
      get cookie_policy_path
      expect(response).to have_http_status(:success)
    end

    it "describes invoice payments instead of checkout storefront language" do
      get cookie_policy_path

      expect(response.body).to include("invoice payments")
      expect(response.body).not_to include("checkout flows")
    end
  end

  describe "GET /gdpr" do
    it "returns http success" do
      get gdpr_path
      expect(response).to have_http_status(:success)
    end

    it "describes invoice payments instead of checkout storefront language" do
      get gdpr_path

      expect(response.body).to include("invoice payments")
      expect(response.body).not_to include("invoice checkout")
    end
  end

  describe "marketing layout footer" do
    it "does not render placeholder social hrefs" do
      get root_path

      expect(response.body).not_to include('aria-label="Twitter"')
      expect(response.body).not_to include('aria-label="LinkedIn"')
      expect(response.body).not_to include('home-footer-social')
    end
  end

  describe "marketing crawl smoke" do
    it "returns success for every nav and footer destination" do
      paths = [
        root_path,
        services_path,
        website_design_path,
        seo_path,
        booking_systems_path,
        follow_up_systems_path,
        about_path,
        process_path,
        portfolio_path,
        pricing_path,
        contact_path,
        blog_path,
        careers_path,
        press_path,
        partners_path,
        help_center_path,
        documentation_path,
        brand_kit_path,
        privacy_path,
        terms_path,
        cookie_policy_path,
        gdpr_path,
        accessibility_path,
        robots_path,
        sitemap_path
      ]

      paths.each do |path|
        get path
        expect(response).to have_http_status(:success), "#{path} failed with #{response.status}"
      end
    end

    it "keeps primary sales CTAs on discovery-call language" do
      [ root_path, about_path, process_path, portfolio_path, contact_path, website_design_path ].each do |path|
        get path
        expect(response.body).to include("Book a discovery call"), "#{path} missing discovery CTA"
      end
    end
  end

  describe "GET /terms" do
    it "returns http success" do
      get terms_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /accessibility" do
    it "returns http success" do
      get accessibility_path
      expect(response).to have_http_status(:success)
    end
  end
end
