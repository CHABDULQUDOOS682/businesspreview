require 'rails_helper'

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
    before do
      # Ensure env vars are set for the test
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("TWILIO_API_KEY").and_return("key")
      allow(ENV).to receive(:[]).with("TWILIO_API_SECRET").and_return("secret")
      allow(ENV).to receive(:[]).with("TWILIO_TWIML_APP_SID").and_return("sid")
      allow(ENV).to receive(:[]).with("TWILIO_ACCOUNT_SID").and_return("acc_sid")
    end

    it "returns a JWT token" do
      get twilio_token_path
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["token"]).to be_present
      expect(json["identity"]).to eq("admin-browser-user")
    end

    it "returns error if env vars are missing" do
      allow(ENV).to receive(:[]).with("TWILIO_API_KEY").and_return(nil)
      get twilio_token_path
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /twilio/connect" do
    it "returns TwiML with dial instruction" do
      post twilio_connect_path, params: { number: "+1234567890" }
      expect(response.body).to include("<Dial")
      expect(response.body).to include("+1234567890")
    end

    it "returns error if number is missing" do
      post twilio_connect_path
      expect(response.body).to include("Error")
    end
  end
end
