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

    it "handles missing business ID" do
      allow(SmsService).to receive(:send_sms).and_return(true)
      post admin_communications_path, params: { to_number: "+1234567890", body: "Hello", business_id: "" }
      expect(response).to redirect_to(admin_communication_path("+1234567890"))
    end

    it "handles SMS sending failure" do
      allow(SmsService).to receive(:send_sms).and_raise(StandardError.new("Twilio Down"))
      post admin_communications_path, params: { to_number: "+1234567890", body: "Hello" }
      expect(response).to redirect_to(admin_communication_path("+1234567890"))
      expect(flash[:alert]).to include("Twilio Down")
    end
  end

  describe "POST /admin/communications/:id/call" do
    before do
      allow(CallService).to receive(:call).and_return(double(sid: "CA_COMM_1", status: "queued"))
      stub_const("ENV", ENV.to_hash.merge("TWILIO_PHONE_NUMBER" => "+15005550006"))
    end

    it "initiates a call, records the employee, and redirects" do
      expect {
        post call_admin_communication_path("+1234567890")
      }.to change(CallLog, :count).by(1)

      expect(response).to redirect_to(admin_communication_path("+1234567890"))
      expect(CallService).to have_received(:call).with(to: "+1234567890")
      expect(CallLog.last).to have_attributes(
        user_id: admin.id,
        to_number: "+1234567890",
        twilio_call_sid: "CA_COMM_1"
      )
    end

    it "handles failed call initiation" do
      allow(CallService).to receive(:call).and_raise(StandardError.new("Call Error"))
      post call_admin_communication_path("+1234567890")
      expect(response).to redirect_to(admin_communication_path("+1234567890"))
      expect(flash[:alert]).to include("Failed to initiate call")
    end
  end

  describe "employee access" do
    let(:employee) { create(:user, :employee) }
    let(:other_employee) { create(:user, :employee) }
    # Employees are pinned to the "nurture" segment, so keep these unsold.
    let(:nurture) { { sold_price: nil, subscription_fee: nil, subscription: false } }
    let!(:mine) { create(:business, phone: "+15550000001", assigned_to: employee, **nurture) }
    let!(:theirs) { create(:business, phone: "+15550000002", assigned_to: other_employee, **nurture) }

    before do
      sign_out admin
      sign_in employee
      allow(SmsService).to receive(:send_sms)
      allow(CallService).to receive(:call).and_return(double(sid: "CA_EMP", status: "queued"))
    end

    it "lists only businesses assigned to the employee" do
      get admin_communications_path

      expect(response).to have_http_status(:success)
      expect(assigns(:businesses)).to include(mine)
      expect(assigns(:businesses)).not_to include(theirs)
    end

    it "hides unattributed conversations from employees" do
      create(:message, business_id: nil, from_number: "+1112223333")
      get admin_communications_path

      expect(assigns(:standalone_conversations)).to be_empty
    end

    it "opens a conversation for an assigned business" do
      get admin_communication_path(mine.phone)

      expect(response).to have_http_status(:success)
      expect(assigns(:business)).to eq(mine)
    end

    it "blocks reading another employee's conversation" do
      get admin_communication_path(theirs.phone)

      expect(response).to redirect_to(admin_communications_path)
      expect(flash[:alert]).to include("do not have access")
    end

    it "blocks sending SMS to a business they are not assigned" do
      expect {
        post admin_communications_path,
             params: { to_number: theirs.phone, body: "hi", business_id: theirs.id }
      }.not_to change(Message, :count)

      expect(SmsService).not_to have_received(:send_sms)
      expect(response).to redirect_to(admin_communications_path)
    end

    it "blocks calling a number they are not assigned" do
      expect {
        post call_admin_communication_path(theirs.phone)
      }.not_to change(CallLog, :count)

      expect(CallService).not_to have_received(:call)
      expect(response).to redirect_to(admin_communications_path)
    end

    it "blocks conversations with numbers that match no business" do
      get admin_communication_path("+15559999999")

      expect(response).to redirect_to(admin_communications_path)
    end

    it "still allows messaging an assigned business" do
      expect {
        post admin_communications_path,
             params: { to_number: mine.phone, body: "hi", business_id: mine.id }
      }.to change(Message, :count).by(1)

      expect(Message.last.business_id).to eq(mine.id)
    end

    it "refuses to attribute a message to a business the employee cannot access" do
      post admin_communications_path,
           params: { to_number: mine.phone, body: "hi", business_id: theirs.id }

      expect(Message.last.business_id).to be_nil
    end
  end
end
