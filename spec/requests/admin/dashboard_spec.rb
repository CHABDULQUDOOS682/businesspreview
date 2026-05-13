require 'rails_helper'

RSpec.describe "Admin::Dashboards", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in admin
  end

  describe "GET /admin" do
    it "returns http success" do
      get admin_root_path
      expect(response).to have_http_status(:success)
    end

    it "assigns the expected dashboard variables" do
      business = create(:business)
      create(:preview_link, business: business)
      create(:message, business: business, direction: "inbound", read_at: nil)

      get admin_root_path
      expect(assigns(:business_count)).to eq(1)
      expect(assigns(:preview_count)).to eq(1)
      expect(assigns(:unread_inbound_count)).to eq(1)
    end

    it "handles super_admin manageable users" do
      sign_out admin
      sign_in create(:user, :super_admin)
      get admin_root_path
      expect(response).to have_http_status(:success)
    end

    it "handles employee manageable users" do
      sign_out admin
      sign_in create(:user, :employee)
      get admin_root_path
      expect(response).to have_http_status(:success)
    end
  end

  context "when not signed in" do
    before { sign_out admin }

    it "redirects to the login page" do
      get admin_root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
