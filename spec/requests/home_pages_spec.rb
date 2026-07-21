require 'rails_helper'

RSpec.describe "HomePages", type: :request do
  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /services" do
    it "returns http success" do
      get services_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /about" do
    it "returns http success" do
      get about_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /workflow" do
    it "returns http success and renders process" do
      get process_path
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:process)
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
      expect(response.body).to include("One-time setup fee: $199")
      expect(response.body).to include("Hot Selling")
      expect(response.body).to include("Project")
      expect(response.body).to include("Starter Website")
      expect(response.body).to include("$999")
      expect(response.body).not_to include("Retainer")
    end
  end

  describe "GET /portfolio" do
    it "returns http success" do
      get portfolio_path
      expect(response).to have_http_status(:success)
    end

    it "renders active portfolio items from the database" do
      create(:portfolio_item, title: "Neighborhood Barbershop", active: true)
      create(:portfolio_item, title: "Hidden Build", active: false)

      get portfolio_path

      expect(response.body).to include("Neighborhood Barbershop")
      expect(response.body).not_to include("Hidden Build")
      expect(response.body).not_to include("Norvik Apparel")
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
  end

  describe "GET /partners" do
    it "returns http success" do
      get partners_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /help_center" do
    it "returns http success" do
      get help_center_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /documentation" do
    it "returns http success" do
      get documentation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /brand_kit" do
    it "returns http success" do
      get brand_kit_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /terms" do
    it "returns http success" do
      get terms_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /cookie_policy" do
    it "returns http success" do
      get cookie_policy_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /gdpr" do
    it "returns http success" do
      get gdpr_path
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
