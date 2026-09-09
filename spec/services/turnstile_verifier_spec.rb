require "rails_helper"

RSpec.describe TurnstileVerifier do
  def with_secret(secret = "secret-key", site: "site-key")
    stub_const("ENV", ENV.to_hash.merge(
      "TURNSTILE_SECRET_KEY" => secret,
      "TURNSTILE_SITE_KEY" => site
    ))
  end

  describe ".site_key" do
    it "returns nil when unset" do
      stub_const("ENV", ENV.to_hash.merge("TURNSTILE_SITE_KEY" => ""))
      expect(described_class.site_key).to be_nil
    end

    it "returns the configured key" do
      with_secret
      expect(described_class.site_key).to eq("site-key")
    end
  end

  describe ".required?" do
    it "is false with no secret configured" do
      stub_const("ENV", ENV.to_hash.merge("TURNSTILE_SECRET_KEY" => "", "TURNSTILE_SITE_KEY" => ""))
      expect(described_class).not_to be_required
    end

    it "is false when only the secret key is set" do
      stub_const("ENV", ENV.to_hash.merge(
        "TURNSTILE_SECRET_KEY" => "secret-key",
        "TURNSTILE_SITE_KEY" => ""
      ))
      allow(Rails.env).to receive(:test?).and_return(false)
      expect(described_class).not_to be_required
    end

    it "is false in the test environment even when configured" do
      with_secret
      expect(described_class).not_to be_required
    end

    it "is true outside test once both keys are configured" do
      with_secret
      allow(Rails.env).to receive(:test?).and_return(false)
      expect(described_class).to be_required
    end
  end

  describe ".valid?" do
    it "passes everything through when Turnstile is not required" do
      expect(described_class.valid?(nil)).to be(true)
    end

    context "when required" do
      before do
        with_secret
        allow(Rails.env).to receive(:test?).and_return(false)
      end

      it "rejects a blank token without calling Cloudflare" do
        expect(Net::HTTP).not_to receive(:new)
        expect(described_class.valid?("")).to be(false)
      end

      it "accepts a token Cloudflare confirms" do
        stub_verification(body: { success: true }.to_json)
        expect(described_class.valid?("token", remote_ip: "1.2.3.4")).to be(true)
      end

      it "rejects a token Cloudflare denies" do
        stub_verification(body: { success: false }.to_json)
        expect(described_class.valid?("token")).to be(false)
      end

      it "fails closed when Cloudflare returns junk" do
        stub_verification(body: "<html>oops</html>")
        expect(described_class.valid?("token")).to be(false)
      end

      it "fails closed when the network is down" do
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:open_timeout=)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_raise(SocketError, "no dns")

        expect(described_class.valid?("token")).to be(false)
      end
    end
  end

  def stub_verification(body:)
    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).and_return(instance_double(Net::HTTPResponse, body: body))
  end
end
