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
      expect(json["prefer_related_applications"]).to eq(false)
      expect(json["icons"]).not_to be_empty
      expect(json["icons"].first["src"]).to include("icon-192.png")
    end
  end

  describe "GET /service-worker.js" do
    it "serves the root service worker" do
      get "/service-worker.js"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("fetch(event.request)")
    end
  end

  describe "GET /admin/service-worker.js" do
    it "serves the service worker through the controller with install headers" do
      get admin_legacy_service_worker_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("javascript")
      expect(response.headers["Service-Worker-Allowed"]).to eq("/")
      expect(response.headers["Cache-Control"]).to include("no-cache")
      expect(response.body).to include("fetch(event.request)")
      expect(response.body).to include("skipWaiting")
    end

    it "falls back to the inline worker when the public file is missing" do
      missing_path = instance_double(Pathname, exist?: false)
      allow(Rails.root).to receive(:join).and_call_original
      allow(Rails.root).to receive(:join).with("public/service-worker.js").and_return(missing_path)

      get admin_legacy_service_worker_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("skipWaiting")
      expect(response.body).to include("clients.claim")
      expect(response.body).to include("fetch(event.request)")
    end
  end

  describe "POST /admin/pwa/install_click" do
    it "records the click for a super admin as json" do
      sign_in super_admin

      post admin_pwa_install_click_path,
           params: { has_prompt: true, service_worker: true, standalone: false },
           as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["ok"]).to eq(true)
      expect(body["has_prompt"]).to eq(true)
      expect(body["manifest_url"]).to include("manifest.webmanifest")
    end

    it "redirects html requests back to the admin root" do
      sign_in super_admin

      post admin_pwa_install_click_path,
           params: { has_prompt: false, service_worker: true, standalone: false }

      expect(response).to redirect_to(admin_root_path)
    end

    it "requires authentication" do
      post admin_pwa_install_click_path, as: :json
      expect(response).to have_http_status(:unauthorized).or have_http_status(:redirect)
    end
  end
end
