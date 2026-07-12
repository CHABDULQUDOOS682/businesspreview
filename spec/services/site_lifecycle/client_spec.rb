# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteLifecycle::Client do
  let(:business) do
    create(
      :business,
      site_api_base_url: "https://sites.example.com",
      site_api_secret: "secret",
      site_external_id: "site-123"
    )
  end
  let(:payment_invoice) { create(:payment_invoice, business: business, sent_at: 2.days.ago, paid_at: Time.current) }
  let(:client) { described_class.new(business) }

  describe "#configured?" do
    it "is true when site api credentials exist" do
      expect(client).to be_configured
    end

    it "is false when credentials are missing" do
      business.update!(site_api_base_url: nil, site_api_secret: nil)
      expect(described_class.new(business)).not_to be_configured
    end
  end

  describe "#deactivate!" do
    it "posts to the deactivate endpoint" do
      stub_request(:post, "https://sites.example.com/api/site_status/deactivate")
        .with(headers: { "X-Site-Api-Secret" => "secret" })
        .to_return(status: 200, body: "{}")

      response = client.deactivate!(payment_invoice: payment_invoice)
      expect(response).to be_a(Net::HTTPSuccess)
    end

    it "raises when the site api is not configured" do
      business.update!(site_api_base_url: nil, site_api_secret: nil)
      expect {
        described_class.new(business).deactivate!(payment_invoice: payment_invoice)
      }.to raise_error(SiteLifecycle::Client::ConfigurationError, /not configured/)
    end

    it "raises when the api returns an error" do
      stub_request(:post, "https://sites.example.com/api/site_status/deactivate")
        .to_return(status: 500, body: "error")

      expect {
        client.deactivate!(payment_invoice: payment_invoice)
      }.to raise_error(SiteLifecycle::Client::ConfigurationError, /500/)
    end
  end

  describe "#reactivate!" do
    it "posts to the reactivate endpoint" do
      stub_request(:post, "https://sites.example.com/api/site_status/reactivate")
        .with(headers: { "X-Site-Api-Secret" => "secret" })
        .to_return(status: 200, body: "{}")

      response = client.reactivate!(payment_invoice: payment_invoice)
      expect(response).to be_a(Net::HTTPSuccess)
    end
  end

  describe "#ping!" do
    it "posts to the ping endpoint with the site id" do
      stub_request(:post, "https://sites.example.com/api/site_status/ping")
        .with(
          headers: { "X-Site-Api-Secret" => "secret" },
          body: hash_including("site_id" => "site-123")
        )
        .to_return(status: 200, body: { ok: true }.to_json)

      response = client.ping!
      expect(response).to be_a(Net::HTTPSuccess)
    end

    it "allows an explicit site_id override" do
      stub_request(:post, "https://sites.example.com/api/site_status/ping")
        .with(body: hash_including("site_id" => "custom-id"))
        .to_return(status: 200, body: "{}")

      expect(client.ping!(site_id: "custom-id")).to be_a(Net::HTTPSuccess)
    end
  end
end
