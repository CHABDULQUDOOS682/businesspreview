# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ContentUpdateWebhooks", type: :request do
  let!(:business) do
    create(
      :business,
      business_number: "B000005",
      site_api_secret: "shared-secret"
    )
  end

  let(:payload) do
    {
      event: "content_update.created",
      business_number: "B000005",
      content_update: {
        id: 42,
        description: "Change hero headline",
        status: "pending",
        requester_email: "owner@example.com",
        created_at: Time.current.iso8601,
        admin_url: "https://admin.example.com/admin/content-updates/42"
      }
    }
  end

  it "creates a task and returns ok" do
    post "/webhooks/content_updates",
         params: payload,
         headers: { "X-Site-Api-Secret" => "shared-secret" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["ok"]).to eq(true)
    expect(AgencyTask.count).to eq(1)
  end

  it "returns unauthorized without a valid secret" do
    post "/webhooks/content_updates",
         params: payload,
         headers: { "X-Site-Api-Secret" => "nope" }

    expect(response).to have_http_status(:unauthorized)
    expect(AgencyTask.count).to eq(0)
  end
end
