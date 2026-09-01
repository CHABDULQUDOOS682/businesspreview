# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilioBalanceService do
  let(:balance_resource) { double("BalanceResource") }
  let(:api_v2010) { double("ApiV2010", balance: balance_resource) }
  let(:api) { double("Api", v2010: api_v2010) }
  let(:client) { double("TwilioClient", api: api) }

  before do
    Rails.cache.clear
  end

  describe ".fetch" do
    it "returns the account balance from Twilio" do
      record = double("BalanceRecord", balance: "12.50", currency: "usd")
      allow(balance_resource).to receive(:fetch).and_return(record)

      result = described_class.fetch(client: client)

      expect(result).to be_available
      expect(result.amount).to eq(BigDecimal("12.50"))
      expect(result.currency).to eq("USD")
      expect(result.error).to be_nil
    end

    it "caches successful responses" do
      record = double("BalanceRecord", balance: "12.50", currency: "usd")
      allow(balance_resource).to receive(:fetch).once.and_return(record)

      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

      described_class.fetch(client: client)
      described_class.fetch(client: client)

      expect(balance_resource).to have_received(:fetch).once
    end

    it "returns an error result when Twilio fails" do
      response = double(status_code: 503, body: { "message" => "Service unavailable" }, headers: {})
      allow(balance_resource).to receive(:fetch).and_raise(
        Twilio::REST::RestError.new("Service unavailable", response)
      )

      result = described_class.fetch(client: client)

      expect(result).not_to be_available
      expect(result.error).to include("Service unavailable")
    end
  end
end
