require 'rails_helper'

RSpec.describe "Admin::PreviewLinks", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business) }
  let!(:preview_link) { create(:preview_link, business: business) }

  before do
    sign_in admin
  end

  describe "POST /admin/businesses/:business_id/preview_links" do
    it "creates a preview link and redirects" do
      expect {
        post admin_business_preview_links_path(business), params: { template: "barber/barber_modern" }
      }.to change(PreviewLink, :count).by(1)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:notice]).to include("Link generated")
    end
  end

  describe "DELETE /admin/preview_links/:id" do
    it "destroys the preview link and redirects" do
      expect {
        delete admin_business_preview_link_path(business, preview_link)
      }.to change(PreviewLink, :count).by(-1)
      expect(response).to redirect_to(admin_business_path(business))
    end
  end
end
