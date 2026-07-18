# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PwaController, type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  describe "GET /admin/manifest.webmanifest" do
    it "returns an installable admin manifest" do
      get admin_manifest_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("application/manifest+json")
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("DevDeBizz Admin")
      expect(json["short_name"]).to eq("DevDeBizz")
      expect(json["start_url"]).to end_with("/admin")
      expect(json["scope"]).to end_with("/")
      expect(json["icons"]).not_to be_empty
    end
  end

  describe "GET /service-worker.js" do
    it "serves the root service worker" do
      get "/service-worker.js"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("fetch(event.request)")
    end
  end

  describe "POST /admin/pwa/install_click" do
    it "records the click for a super admin" do
      sign_in super_admin

      post admin_pwa_install_click_path,
           params: { has_prompt: true, service_worker: true, standalone: false },
           as: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["ok"]).to eq(true)
    end

    it "requires authentication" do
      post admin_pwa_install_click_path, as: :json
      expect(response).to have_http_status(:unauthorized).or have_http_status(:redirect)
    end
  end
end
