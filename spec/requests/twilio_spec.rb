require "rails_helper"

RSpec.describe "Twilios", type: :request do
  describe "POST /twilio/voice" do
    it "returns TwiML xml" do
      post twilio_voice_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("<Say")
      expect(response.body).to include("Abdul")
    end
  end

  describe "POST /twilio/sms" do
    let!(:business) { create(:business, phone: "+1234567890") }
    let(:params) do
      {
        From: "+1234567890",
        To: "+0987654321",
        Body: "Incoming text message"
      }
    end

    it "records the message and returns TwiML" do
      expect {
        post twilio_sms_path, params: params
      }.to change(Message, :count).by(1)

      expect(response).to have_http_status(:success)
      message = Message.last
      expect(message.from_number).to eq("+1234567890")
      expect(message.body).to eq("Incoming text message")
      expect(message.direction).to eq("inbound")
      expect(message.business_id).to eq(business.id)
    end
  end

  describe "GET /twilio/token" do
    let(:user) { create(:user, :admin) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TWILIO_API_KEY").and_return("key")
      allow(ENV).to receive(:[]).with("TWILIO_API_SECRET").and_return("secret")
      allow(ENV).to receive(:[]).with("TWILIO_TWIML_APP_SID").and_return("sid")
      allow(ENV).to receive(:[]).with("TWILIO_ACCOUNT_SID").and_return("acc_sid")
      # AccessToken and present? check use ENV[] and sometimes fetch
      allow(ENV).to receive(:present?)
      %w[TWILIO_API_KEY TWILIO_API_SECRET TWILIO_TWIML_APP_SID].each do |key|
        allow(ENV).to receive(:[]).with(key).and_return("value")
      end
      stub_const("ENV", ENV.to_hash.merge(
        "TWILIO_API_KEY" => "key",
        "TWILIO_API_SECRET" => "secret",
        "TWILIO_TWIML_APP_SID" => "sid",
        "TWILIO_ACCOUNT_SID" => "acc_sid"
      ))
    end

    it "requires authentication" do
      get twilio_token_path
      expect(response).to have_http_status(:redirect).or have_http_status(:unauthorized)
    end

    it "returns a JWT token for the signed-in user" do
      sign_in user
      get twilio_token_path
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["identity"]).to eq("user-#{user.id}")
    end

    it "returns error if env vars are missing" do
      sign_in user
      stub_const("ENV", ENV.to_hash.merge(
        "TWILIO_API_KEY" => "",
        "TWILIO_API_SECRET" => "secret",
        "TWILIO_TWIML_APP_SID" => "sid",
        "TWILIO_ACCOUNT_SID" => "acc_sid"
      ))
      get twilio_token_path
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /twilio/connect" do
    let(:user) { create(:user) }
    let!(:business) { create(:business, phone: "+1234567890") }

    before do
      stub_const("ENV", ENV.to_hash.merge("TWILIO_PHONE_NUMBER" => "+15005550006"))
    end

    it "returns TwiML with dial instruction and records the call log" do
      expect {
        post twilio_connect_path, params: {
          number: "+1234567890",
          CallSid: "CA_CONNECT_1",
          UserId: user.id,
          BusinessId: business.id,
          Caller: "client:user-#{user.id}"
        }
      }.to change(CallLog, :count).by(1)

      expect(response.body).to include("<Dial")
      expect(response.body).to include("+1234567890")
      expect(response.body).to include("dial_status")

      call_log = CallLog.last
      expect(call_log.user).to eq(user)
      expect(call_log.business).to eq(business)
      expect(call_log.twilio_call_sid).to eq("CA_CONNECT_1")
    end

    it "returns error if number is missing" do
      post twilio_connect_path
      expect(response.body).to include("Error")
    end
  end

  describe "POST /twilio/dial_status" do
    it "updates the call log duration and status" do
      call_log = create(:call_log, twilio_call_sid: "CA_STATUS", status: "initiated", duration_seconds: nil)

      post twilio_dial_status_path, params: {
        CallSid: "CA_STATUS",
        DialCallStatus: "completed",
        DialCallDuration: "42"
      }

      expect(response).to have_http_status(:ok)
      expect(call_log.reload).to have_attributes(status: "completed", duration_seconds: 42)
    end
  end
end
