require 'rails_helper'

RSpec.describe "Admin::CallLogs", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business, name: "Northside Barber") }
  let(:service) { instance_double(TwilioCallLogService) }

  before do
    sign_in admin
    allow(TwilioCallLogService).to receive(:new).and_return(service)
    allow(service).to receive(:recent_calls).and_return([])
  end

  describe "GET /admin/call_logs" do
    it "shows call logs with business links" do
      call_log = TwilioCallLogService::Record.new(
        business: business,
        direction: "outbound",
        from_number: "+15550000001",
        to_number: "+15550000002",
        sid: "CA123",
        status: "completed",
        duration_seconds: 125,
        logged_at: Time.current
      )
      allow(service).to receive(:recent_calls).and_return([ call_log ])

      get admin_call_logs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Call Logs")
      expect(response.body).to include(call_log.direction_label)
      expect(response.body).to include("+15550000001")
      expect(response.body).to include("+15550000002")
      expect(response.body).to include("CA123")
      expect(response.body).to include(admin_business_path(business))
      expect(response.body).to include("Northside Barber")
    end

    it "filters by direction" do
      outbound_call = TwilioCallLogService::Record.new(business: business, direction: "outbound", sid: "CA1")
      inbound_call = TwilioCallLogService::Record.new(business: create(:business, name: "Inbound Co"), direction: "inbound", sid: "CA2")
      allow(service).to receive(:recent_calls).and_return([ outbound_call, inbound_call ])

      get admin_call_logs_path(direction: "outbound")

      expect(response.body).to include(outbound_call.business.name)
      expect(response.body).not_to include(inbound_call.business.name)
    end

    it "redirects employees" do
      sign_out admin
      sign_in create(:user, :employee)

      get admin_call_logs_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("do not have access")
    end

    it "shows a Twilio error if call records cannot be loaded" do
      allow(service).to receive(:recent_calls).and_raise(StandardError, "Twilio unavailable")

      get admin_call_logs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Twilio call records could not be loaded")
      expect(response.body).to include("Twilio unavailable")
    end
  end
end
