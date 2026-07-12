# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContentUpdateWebhookService do
  let!(:business) do
    create(
      :business,
      business_number: "B000005",
      site_api_secret: "shared-secret"
    )
  end

  let(:payload) do
    {
      "event" => "content_update.created",
      "business_number" => "B000005",
      "content_update" => {
        "id" => 42,
        "description" => "Change hero headline on home page",
        "status" => "pending",
        "requester_email" => "owner@example.com",
        "requester_name" => "Owner",
        "created_at" => "2026-07-12T10:00:00Z",
        "admin_url" => "https://admin.example.com/admin/content-updates/42"
      }
    }
  end

  it "creates an agency task" do
    result = described_class.call(payload: payload, secret: "shared-secret")

    expect(result.success?).to eq(true)
    expect(result.task).to have_attributes(
      source: "content_update",
      external_id: "42",
      business_id: business.id,
      status: "pending",
      external_url: "https://admin.example.com/admin/content-updates/42"
    )
    expect(AgencyTask.count).to eq(1)
  end

  it "updates an existing task idempotently" do
    described_class.call(payload: payload, secret: "shared-secret")
    payload["content_update"]["status"] = "completed"
    payload["content_update"]["description"] = "Done — hero updated"

    result = described_class.call(payload: payload, secret: "shared-secret")

    expect(result.success?).to eq(true)
    expect(AgencyTask.count).to eq(1)
    expect(result.task.reload).to have_attributes(
      status: "completed",
      description: "Done — hero updated"
    )
  end

  it "rejects invalid secrets" do
    result = described_class.call(payload: payload, secret: "wrong")

    expect(result.success?).to eq(false)
    expect(result.http_status).to eq(:unauthorized)
  end

  it "rejects unknown business numbers" do
    payload["business_number"] = "B999999"
    result = described_class.call(payload: payload, secret: "shared-secret")

    expect(result.success?).to eq(false)
    expect(result.http_status).to eq(:not_found)
  end

  it "rejects when the business has no site API secret configured" do
    business.update!(site_api_secret: nil)
    result = described_class.call(payload: payload, secret: "shared-secret")

    expect(result.success?).to eq(false)
    expect(result.http_status).to eq(:unauthorized)
    expect(result.error).to include("not configured")
  end

  it "returns unprocessable when the task cannot be saved" do
    allow_any_instance_of(AgencyTask).to receive(:save!).and_raise(
      ActiveRecord::RecordInvalid.new(AgencyTask.new)
    )

    result = described_class.call(payload: payload, secret: "shared-secret")

    expect(result.success?).to eq(false)
    expect(result.http_status).to eq(:unprocessable_entity)
  end

  it "ignores invalid created_at values" do
    payload["content_update"]["created_at"] = "not-a-time"

    result = described_class.call(payload: payload, secret: "shared-secret")

    expect(result.success?).to eq(true)
    expect(result.task.requested_at).to be_present
  end

  it "rescues parse errors from created_at" do
    allow(Time.zone).to receive(:parse).and_raise(ArgumentError)

    result = described_class.call(payload: payload, secret: "shared-secret")

    expect(result.success?).to eq(true)
    expect(result.task.requested_at).to be_present
  end
end
