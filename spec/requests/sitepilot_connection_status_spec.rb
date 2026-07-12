# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sitepilot connection status webhook", type: :request do
  let!(:business) do
    create(
      :business,
      business_number: "B000006",
      site_external_id: "tutwiler-barber-shop",
      site_api_base_url: "http://dashboard.lvh.me:3001",
      site_api_secret: "local-dev-secret"
    )
  end

  it "returns ok when connection values match" do
    post "/webhooks/sitepilot/connection_status",
         params: {
           business_number: "B000006",
           site_external_id: "tutwiler-barber-shop",
           site_api_base_url: "http://dashboard.lvh.me:3001"
         },
         headers: { "X-Site-Api-Secret" => "local-dev-secret", "ACCEPT" => "application/json" },
         as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include("ok" => true, "configured" => true)
  end

  it "returns unprocessable when connection fields are missing" do
    business.update!(site_external_id: nil, site_api_base_url: nil, site_api_secret: nil)

    post "/webhooks/sitepilot/connection_status",
         params: { business_number: "B000006" },
         as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body["ok"]).to eq(false)
  end
end
