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

  describe "GET /blog" do
    it "returns http success" do
      get blog_path
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
