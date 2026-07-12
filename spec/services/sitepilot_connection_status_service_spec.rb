# frozen_string_literal: true

require "rails_helper"

RSpec.describe SitepilotConnectionStatusService do
  let(:business) do
    create(
      :business,
      business_number: "B000006",
      site_external_id: "tutwiler-barber-shop",
      site_api_base_url: "http://dashboard.lvh.me:3001",
      site_api_secret: "local-dev-secret"
    )
  end

  it "reports missing connection fields" do
    business.update!(site_external_id: nil, site_api_base_url: nil, site_api_secret: nil)

    result = described_class.call(
      business_number: "B000006",
      site_external_id: "tutwiler-barber-shop",
      site_api_base_url: "http://dashboard.lvh.me:3001",
      request_secret: "local-dev-secret"
    )

    expect(result.ok).to eq(false)
    expect(result.payload[:missing]).to include("Site External ID", "Site API Base URL", "Site API Secret")
  end

  it "passes when CRM values match SitePilot" do
    result = described_class.call(
      business_number: business.business_number,
      site_external_id: business.site_external_id,
      site_api_base_url: business.site_api_base_url,
      request_secret: business.site_api_secret
    )

    expect(result.ok).to eq(true)
    expect(result.payload[:configured]).to eq(true)
  end

  it "fails when business number is unknown" do
    result = described_class.call(business_number: "B999999")

    expect(result.ok).to eq(false)
    expect(result.http_status).to eq(:not_found)
  end

  it "requires business_number" do
    result = described_class.call(business_number: "  ")

    expect(result.ok).to eq(false)
    expect(result.http_status).to eq(:unprocessable_entity)
    expect(result.payload[:missing]).to include("Business Number")
  end

  it "fails when the site API secret does not match" do
    result = described_class.call(
      business_number: business.business_number,
      site_external_id: business.site_external_id,
      site_api_base_url: business.site_api_base_url,
      request_secret: "wrong-secret"
    )

    expect(result.ok).to eq(false)
    expect(result.http_status).to eq(:unauthorized)
    expect(result.payload[:mismatches]).to include("Site API Secret")
  end

  it "reports a Site External ID mismatch" do
    result = described_class.call(
      business_number: business.business_number,
      site_external_id: "other-slug",
      site_api_base_url: business.site_api_base_url
    )

    expect(result.ok).to eq(false)
    expect(result.payload[:mismatches].join).to include("Site External ID")
  end

  it "reports a Site API Base URL mismatch" do
    result = described_class.call(
      business_number: business.business_number,
      site_external_id: business.site_external_id,
      site_api_base_url: "http://wrong.example.com"
    )

    expect(result.ok).to eq(false)
    expect(result.payload[:mismatches].join).to include("Site API Base URL")
  end
end
