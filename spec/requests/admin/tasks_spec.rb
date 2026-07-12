# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Tasks", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:business) { create(:business, business_number: "B000001", name: "Pro Clinic") }
  let!(:task) { create(:agency_task, business: business, title: "Update services page", status: "pending") }

  before do
    sign_in admin
  end

  describe "GET /admin/tasks" do
    it "lists agency tasks" do
      get admin_tasks_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Update services page")
      expect(response.body).to include("Open in SitePilot")
    end

    it "filters by status" do
      create(:agency_task, business: business, title: "Completed item", status: "completed", external_id: "99")

      get admin_tasks_path, params: { status: "pending" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Update services page")
      expect(response.body).not_to include("Completed item")
    end

    it "searches by query" do
      get admin_tasks_path, params: { q: "services" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Update services page")
    end
  end
end
