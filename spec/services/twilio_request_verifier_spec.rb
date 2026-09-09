require "rails_helper"

RSpec.describe TwilioRequestVerifier do
  let(:auth_token) { "test_auth_token" }
  let(:url) { "https://example.com/twilio/connect" }
  let(:payload) { { "number" => "+15551234567", "CallSid" => "CA123" } }

  def build_request(signature:, params: payload, request_url: url)
    instance_double(
      ActionDispatch::Request,
      env: { described_class::SIGNATURE_HEADER => signature },
      original_url: request_url,
      request_parameters: params
    )
  end

  def valid_signature_for(request_url = url, params = payload)
    Twilio::Security::RequestValidator.new(auth_token).build_signature_for(request_url, params)
  end

  describe ".enabled?" do
    it "is off in the test environment by default" do
      expect(described_class).not_to be_enabled
    end

    it "is on outside development and test" do
      allow(Rails.env).to receive(:local?).and_return(false)
      expect(described_class).to be_enabled
    end

    it "can be forced on by env var" do
      stub_const("ENV", ENV.to_hash.merge("TWILIO_VERIFY_WEBHOOKS" => "true"))
      expect(described_class).to be_enabled
    end

    it "can be forced off by env var" do
      allow(Rails.env).to receive(:local?).and_return(false)
      stub_const("ENV", ENV.to_hash.merge("TWILIO_VERIFY_WEBHOOKS" => "false"))
      expect(described_class).not_to be_enabled
    end
  end

  describe ".valid?" do
    it "waves requests through when verification is disabled" do
      expect(described_class.valid?(build_request(signature: ""))).to be(true)
    end

    context "when verification is enabled" do
      before do
        stub_const("ENV", ENV.to_hash.merge(
          "TWILIO_VERIFY_WEBHOOKS" => "true",
          "TWILIO_AUTH_TOKEN" => auth_token
        ))
      end

      it "accepts a correctly signed request" do
        request = build_request(signature: valid_signature_for)
        expect(described_class.valid?(request)).to be(true)
      end

      it "rejects a request with no signature" do
        expect(described_class.valid?(build_request(signature: ""))).to be(false)
      end

      it "rejects a forged signature" do
        expect(described_class.valid?(build_request(signature: "bogus"))).to be(false)
      end

      it "rejects when the signed params have been tampered with" do
        request = build_request(
          signature: valid_signature_for,
          params: payload.merge("number" => "+9999999999")
        )
        expect(described_class.valid?(request)).to be(false)
      end

      it "rejects when the signed url does not match" do
        request = build_request(
          signature: valid_signature_for,
          request_url: "https://evil.example.com/twilio/connect"
        )
        expect(described_class.valid?(request)).to be(false)
      end

      it "fails closed when the auth token is missing" do
        stub_const("ENV", ENV.to_hash.merge(
          "TWILIO_VERIFY_WEBHOOKS" => "true",
          "TWILIO_AUTH_TOKEN" => ""
        ))
        expect(described_class.valid?(build_request(signature: "anything"))).to be(false)
      end

      it "fails closed when the validator raises" do
        allow(Twilio::Security::RequestValidator).to receive(:new).and_raise(StandardError, "boom")
        expect(described_class.valid?(build_request(signature: "sig"))).to be(false)
      end
    end
  end
end
