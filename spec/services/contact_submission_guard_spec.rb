require "rails_helper"

RSpec.describe ContactSubmissionGuard do
  def guard(honeypot: nil, turnstile_token: nil, remote_ip: "1.2.3.4")
    described_class.new(
      honeypot: honeypot,
      turnstile_token: turnstile_token,
      remote_ip: remote_ip
    )
  end

  describe "#honeypot_triggered?" do
    it "is false when the hidden field is left alone" do
      expect(guard).not_to be_honeypot_triggered
    end

    it "is true when a bot fills the hidden field" do
      expect(guard(honeypot: "https://spam.example")).to be_honeypot_triggered
    end
  end

  describe "#turnstile_failed?" do
    it "is false when Turnstile is not configured" do
      allow(TurnstileVerifier).to receive(:required?).and_return(false)
      expect(guard).not_to be_turnstile_failed
    end

    it "is true when Turnstile rejects the token" do
      allow(TurnstileVerifier).to receive(:required?).and_return(true)
      allow(TurnstileVerifier).to receive(:valid?).and_return(false)

      expect(guard(turnstile_token: "bad")).to be_turnstile_failed
    end

    it "is false when Turnstile accepts the token" do
      allow(TurnstileVerifier).to receive(:required?).and_return(true)
      allow(TurnstileVerifier).to receive(:valid?).and_return(true)

      expect(guard(turnstile_token: "good")).not_to be_turnstile_failed
    end

    it "passes the remote ip through to Turnstile" do
      allow(TurnstileVerifier).to receive(:required?).and_return(true)
      allow(TurnstileVerifier).to receive(:valid?).and_return(true)

      guard(turnstile_token: "good", remote_ip: "9.9.9.9").turnstile_failed?

      expect(TurnstileVerifier).to have_received(:valid?).with("good", remote_ip: "9.9.9.9")
    end
  end

  describe "#accept?" do
    it "accepts a clean submission" do
      expect(guard).to be_accept
    end

    it "rejects a submission that tripped the honeypot" do
      expect(guard(honeypot: "bot")).not_to be_accept
    end

    it "rejects a submission that failed Turnstile" do
      allow(TurnstileVerifier).to receive(:required?).and_return(true)
      allow(TurnstileVerifier).to receive(:valid?).and_return(false)

      expect(guard(turnstile_token: "bad")).not_to be_accept
    end
  end
end
