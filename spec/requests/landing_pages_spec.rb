require 'rails_helper'

RSpec.describe "LandingPages", type: :request do
  let(:business) { create(:business) }
  let(:preview_link) { create(:preview_link, business: business, template: "barber/barber_modern") }

  describe "GET /preview/:uuid" do
    it "returns http success and increments visit counts" do
      expect {
        get landing_page_path(preview_link.uuid)
      }.to change { preview_link.reload.visit_count }.by(1)
       .and change { business.reload.visit_count }.by(1)

      expect(response).to have_http_status(:success)
      expect(preview_link.clicked_at).to be_present
      expect(preview_link.ip_address).to be_present
    end

    it "does not update clicked_at on second visit" do
      preview_link.update(clicked_at: 1.day.ago)
      expect {
        get landing_page_path(preview_link.uuid)
      }.not_to change { preview_link.reload.clicked_at }
    end

    it "returns 404 for invalid uuid" do
      get landing_page_path("invalid-uuid")
      expect(response).to have_http_status(:not_found)
    end
  end
end
