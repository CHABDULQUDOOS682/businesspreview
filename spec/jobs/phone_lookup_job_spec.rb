# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhoneLookupJob, type: :job do
  let(:business) { create(:business, phone: "+16232481437") }
  let(:lookup_resource) { double("lookup_resource") }
  let(:lookups_v2) { double("lookups_v2") }
  let(:lookups) { double("lookups", v2: lookups_v2) }
  let(:twilio_client) { double("TWILIO_CLIENT", lookups: lookups) }

  before do
    stub_const("TWILIO_CLIENT", twilio_client)
    allow(lookups_v2).to receive(:phone_numbers).with(business.phone).and_return(lookup_resource)
  end

  it "stores the line type from Twilio Lookup v2" do
    allow(lookup_resource).to receive(:fetch)
      .with(fields: "line_type_intelligence")
      .and_return(double(line_type_intelligence: { "type" => "landline" }))

    described_class.perform_now(business.id)

    business.reload
    expect(business.phone_line_type).to eq("landline")
    expect(business.phone_lookup_checked_at).to be_present
    expect(business.phone_lookup_error).to be_nil
  end

  it "stores the Twilio error when the lookup fails" do
    response = double(
      status_code: 404,
      body: { "code" => 20404, "message" => "The requested resource was not found" },
      headers: {}
    )
    allow(lookup_resource).to receive(:fetch).and_raise(Twilio::REST::RestError.new("Not found", response))

    described_class.perform_now(business.id)

    business.reload
    expect(business.phone_lookup_checked_at).to be_present
    expect(business.phone_lookup_error).to be_present
    expect(business.phone_line_type).to be_nil
  end

  it "returns early when the business has no phone" do
    business.update_columns(phone: "")

    expect(twilio_client).not_to receive(:lookups)
    described_class.perform_now(business.id)

    expect(business.reload.phone_lookup_checked_at).to be_nil
  end

  it "no-ops when the business no longer exists" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
