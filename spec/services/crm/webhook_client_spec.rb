# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crm::WebhookClient do
  let(:business) do
    create(
      :business,
      business_number: "B000005",
      site_api_base_url: "http://dashboard.lvh.me:3001",
      site_api_secret: "shared-secret"
    )
  end

  it "is configured when site API fields and business_number are present" do
    expect(described_class.new(business)).to be_configured
  end

  it "posts to the CRM webhook endpoint with shared secret headers" do
    http = instance_double(Net::HTTP)
    response = Net::HTTPOK.new("1.1", "200", "OK")
    allow(response).to receive(:body).and_return("")
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)

    expect(http).to receive(:request) do |req|
      expect(req).to be_a(Net::HTTP::Post)
      expect(req.path).to eq("/integrations/crm/webhooks")
      expect(req["X-Crm-Webhook-Secret"]).to eq("shared-secret")
      expect(req["X-Site-Api-Secret"]).to eq("shared-secret")
      body = JSON.parse(req.body)
      expect(body).to include(
        "event" => "subscription_renewed",
        "business_number" => "B000005",
        "billing_message" => "Paid"
      )
      response
    end

    described_class.new(business).deliver!(
      event: "subscription_renewed",
      billing_message: "Paid",
      billing_level: "success"
    )
  end

  it "raises when not configured" do
    business.update!(site_api_base_url: nil)

    expect {
      described_class.new(business).deliver!(event: "payment_received")
    }.to raise_error(Crm::WebhookClient::ConfigurationError)
  end

  it "raises when the CRM webhook returns an error" do
    http = instance_double(Net::HTTP)
    response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
    allow(response).to receive(:body).and_return("nope")
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).and_return(response)

    expect {
      described_class.new(business).deliver!(event: "payment_received")
    }.to raise_error(Crm::WebhookClient::Error, /400/)
  end
end
