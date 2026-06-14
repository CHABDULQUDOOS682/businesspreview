require 'rails_helper'

RSpec.describe "Admin::PreviewLinks", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user, role: "employee") }
  let(:business) { create(:business) }
  let!(:preview_link) { create(:preview_link, business: business) }

  before do
    sign_in admin
  end

  describe "GET /admin/preview_links" do
    it "returns success for admin" do
      get admin_preview_links_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Prototype Links")
      expect(response.body).to include(business.name)
      expect(response.body).to include("Generate Link")
    end

    it "filters by business" do
      other_business = create(:business, name: "Other Biz")
      create(:preview_link, business: other_business, template: "others/corporate_pro")

      get admin_preview_links_path, params: { business_id: business.id }

      expect(response).to have_http_status(:success)
      expect(assigns(:preview_links)).to include(preview_link)
      expect(assigns(:preview_links).map(&:business_id).uniq).to eq([ business.id ])
    end

    context "when logged in as employee" do
      before { sign_in employee }

      it "returns success" do
        get admin_preview_links_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Generate Prototype Link")
      end
    end
  end

  describe "POST /admin/preview_links" do
    it "creates a preview link and redirects to the index" do
      expect {
        post admin_preview_links_path, params: {
          business_id: business.id,
          template: "barber/barber_modern"
        }
      }.to change(PreviewLink, :count).by(1)

      expect(response).to redirect_to(admin_preview_links_path)
      expect(flash[:notice]).to include("Prototype link created")
    end
  end

  describe "DELETE /admin/preview_links/:id" do
    it "destroys the preview link and redirects" do
      expect {
        delete admin_preview_link_path(preview_link)
      }.to change(PreviewLink, :count).by(-1)

      expect(response).to redirect_to(admin_preview_links_path)
      expect(flash[:notice]).to eq("Prototype link deleted.")
    end
  end
end
