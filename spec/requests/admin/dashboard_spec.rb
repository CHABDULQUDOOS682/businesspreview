require 'rails_helper'

RSpec.describe "Admin::Dashboards", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:twilio_balance) do
    TwilioBalanceService::Result.new(
      amount: BigDecimal("42.75"),
      currency: "USD",
      fetched_at: Time.current,
      error: nil
    )
  end

  before do
    sign_in admin
    allow(TwilioBalanceService).to receive(:fetch).and_return(twilio_balance)
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
      expect(assigns(:business_count)).to eq(Business.count)
      expect(assigns(:preview_count)).to eq(PreviewLink.count)
      expect(assigns(:unread_inbound_count)).to eq(Message.inbound.unread.count)
      expect(assigns(:business_count)).to be >= 1
      expect(assigns(:preview_count)).to be >= 1
      expect(assigns(:unread_inbound_count)).to be >= 1
    end

    it "handles super_admin manageable users" do
      sign_out admin
      sign_in create(:user, :super_admin)
      get admin_root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Twilio balance")
      expect(response.body).to include("$42.75")
    end

    it "shows twilio balance for admins" do
      get admin_root_path

      expect(response.body).to include("Twilio balance")
      expect(response.body).to include("$42.75")
    end

    it "handles employee manageable users" do
      sign_out admin
      sign_in create(:user, :employee)
      get admin_root_path
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Twilio balance")
      expect(response.body).not_to include("Prototype Links")
      expect(response.body).not_to include("Links generated")
      expect(response.body).not_to include("Available Templates")
      expect(response.body).not_to include("Recent Engagement")
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
