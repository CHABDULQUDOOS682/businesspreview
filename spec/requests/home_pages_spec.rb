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

  describe "GET /privacy" do
    it "returns http success" do
      get privacy_path
      expect(response).to have_http_status(:success)
    end
  end
end
