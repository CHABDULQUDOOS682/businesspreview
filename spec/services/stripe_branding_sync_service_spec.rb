require "rails_helper"

RSpec.describe StripeBrandingSyncService do
  describe ".call!" do
    it "uploads logo/icon files and updates Stripe account branding" do
      allow(Stripe).to receive(:api_key).and_return("sk_test_123")

      logo_file = double(id: "file_logo")
      icon_file = double(id: "file_icon")
      account = double(id: "acct_123")

      expect(Stripe::File).to receive(:create).with(hash_including(purpose: "business_logo")).and_return(logo_file)
      expect(Stripe::File).to receive(:create).with(hash_including(purpose: "business_icon")).and_return(icon_file)
      expect(Stripe::Account).to receive(:retrieve).and_return(account)
      expect(Stripe::Account).to receive(:update).with(
        "acct_123",
        settings: {
          branding: {
            logo: "file_logo",
            icon: "file_icon",
            primary_color: "#213885",
            secondary_color: "#5F3475"
          }
        }
      )

      result = described_class.call!

      expect(result[:account_id]).to eq("acct_123")
      expect(result[:public_logo_url]).to include("/brand/logo.svg")
    end
  end
end
