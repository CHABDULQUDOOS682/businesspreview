require 'rails_helper'

RSpec.describe "Admin::Communications", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business, phone: "+1234567890") }

  before do
    sign_in admin
  end

  describe "GET /admin/communications" do
    it "returns http success" do
      create(:message, business_id: nil, from_number: "+1112223333")
      get admin_communications_path
      expect(response).to have_http_status(:success)
      expect(assigns(:standalone_conversations)).not_to be_empty
    end
  end

  describe "GET /admin/communications/:id" do
    it "returns http success" do
      get admin_communication_path("+1234567890")
      expect(response).to have_http_status(:success)
    end

    it "matches business by last 10 digits" do
      business.update(phone: "1234567890")
      get admin_communication_path("+11234567890")
      expect(assigns(:business)).to eq(business)
    end

    it "handles conversations without a business" do
      get admin_communication_path("+0000000000")
      expect(response).to have_http_status(:success)
    end

    it "handles missing number" do
      get admin_communication_path(" ")
      expect(assigns(:messages)).to be_empty
    end
  end

  describe "POST /admin/communications" do
    before do
      allow(SmsService).to receive(:send_sms)
    end

    it "sends a message and redirects" do
      expect {
        post admin_communications_path, params: { to_number: "+1234567890", body: "Hello", business_id: business.id }
      }.to change(Message, :count).by(1)
      expect(response).to redirect_to(admin_communication_path("+1234567890"))
      expect(SmsService).to have_received(:send_sms).with(to: "+1234567890", message: "Hello")
    end

    it "handles failed message sending" do
      allow(SmsService).to receive(:send_sms).and_raise(StandardError.new("Twilio Error"))
      post admin_communications_path, params: { to_number: "+1234567890", body: "Hello" }
      expect(response).to redirect_to(admin_communication_path("+1234567890"))
      expect(flash[:alert]).to include("Failed to send")
    end
  end

  describe "POST /admin/communications/bulk_create" do
    let(:business_ids) { [ business.id ] }

    before do
      allow(SmsService).to receive(:send_sms)
    end

    it "sends messages to selected businesses and redirects" do
      expect {
        post bulk_create_admin_communications_path, params: { business_ids: [ business.id ], body: "Bulk Hello" }
      }.to change(Message, :count).by(1)
      expect(response).to redirect_to(admin_businesses_path)
      expect(SmsService).to have_received(:send_sms).with(to: business.phone, message: "Bulk Hello")
    end

    it "skips businesses without phone numbers" do
      business.update_columns(phone: nil)
      post bulk_create_admin_communications_path, params: { business_ids: [ business.id ], body: "Bulk Hello" }
      expect(flash[:notice]).to include("Sent 0 messages")
    end

    it "handles individual message failures" do
      allow(SmsService).to receive(:send_sms).and_raise(StandardError.new("Twilio error"))
      post bulk_create_admin_communications_path, params: { business_ids: [ business.id ], body: "Bulk Hello" }
      expect(flash[:notice]).to include("1 failed")
    end

    it "redirects if params are missing" do
      post bulk_create_admin_communications_path, params: { business_ids: [], body: "" }
      expect(response).to redirect_to(admin_businesses_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /admin/communications/:id/call" do
    before do
      allow(CallService).to receive(:call)
    end

    it "initiates a call and redirects" do
      post call_admin_communication_path("+1234567890")
      expect(response).to redirect_to(admin_communication_path("+1234567890"))
      expect(CallService).to have_received(:call).with(to: "+1234567890")
    end

    it "handles failed call initiation" do
      allow(CallService).to receive(:call).and_raise(StandardError.new("Call Error"))
      post call_admin_communication_path("+1234567890")
      expect(response).to redirect_to(admin_communication_path("+1234567890"))
      expect(flash[:alert]).to include("Failed to initiate call")
    end
  end
end
