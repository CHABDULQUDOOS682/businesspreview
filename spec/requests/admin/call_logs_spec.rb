require "rails_helper"

RSpec.describe "Admin::CallLogs", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user, email: "caller@example.com", name: "Casey Caller") }
  let(:business) { create(:business, name: "Northside Barber") }

  before { sign_in admin }

  describe "GET /admin/call_logs" do
    it "shows employee and business for each call" do
      create(
        :call_log,
        user: employee,
        business: business,
        from_number: "+15550000001",
        to_number: business.phone,
        twilio_call_sid: "CA123",
        status: "completed",
        duration_seconds: 125
      )

      get admin_call_logs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Call Logs")
      expect(response.body).to include("Casey Caller")
      expect(response.body).to include("Northside Barber")
      expect(response.body).to include(admin_business_path(business))
      expect(response.body).to include("CA123")
      expect(response.body).to include("Outbound")
    end

    it "filters by search query including employee" do
      create(:call_log, user: employee, business: business, twilio_call_sid: "CA_SEARCH")
      create(:call_log, user: create(:user, name: "Other"), business: create(:business, name: "Hidden Co"), twilio_call_sid: "CA_OTHER")

      get admin_call_logs_path, params: { q: "Casey" }

      expect(response.body).to include("CA_SEARCH")
      expect(response.body).not_to include("CA_OTHER")
    end

    it "filters by employee" do
      create(:call_log, user: employee, business: business, twilio_call_sid: "CA1")
      create(:call_log, user: create(:user, name: "Other Emp"), business: business, twilio_call_sid: "CA2")

      get admin_call_logs_path, params: { user_id: employee.id }

      expect(response.body).to include("CA1")
      expect(response.body).not_to include("CA2")
    end

    it "filters by direction" do
      create(:call_log, user: employee, business: business, direction: "outbound", twilio_call_sid: "CA_OUT")
      create(:call_log, user: employee, business: create(:business, name: "Inbound Co"), direction: "inbound", twilio_call_sid: "CA_IN")

      get admin_call_logs_path(direction: "outbound")

      expect(response.body).to include("CA_OUT")
      expect(response.body).not_to include("CA_IN")
    end

    it "redirects employees" do
      sign_out admin
      sign_in create(:user)

      get admin_call_logs_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("do not have access")
    end
  end
end
