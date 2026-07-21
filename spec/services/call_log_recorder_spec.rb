# frozen_string_literal: true

require "rails_helper"

RSpec.describe CallLogRecorder do
  let(:user) { create(:user) }
  let(:business) { create(:business, phone: "+16232481437") }

  before { stub_const("ENV", ENV.to_hash.merge("TWILIO_PHONE_NUMBER" => "+15005550006")) }

  it "records an outbound call with employee and business" do
    call_log = described_class.record_outbound!(
      user: user,
      business: business,
      to_number: business.phone,
      twilio_call_sid: "CA123"
    )

    expect(call_log).to have_attributes(
      user_id: user.id,
      business_id: business.id,
      to_number: business.phone,
      direction: "outbound",
      twilio_call_sid: "CA123"
    )
  end

  it "matches business by phone when business is not passed" do
    call_log = described_class.record_outbound!(
      user: user,
      to_number: business.phone,
      twilio_call_sid: "CA456"
    )

    expect(call_log.business).to eq(business)
  end

  it "creates a call log without a Twilio SID" do
    call_log = described_class.record_outbound!(
      user: user,
      business: business,
      to_number: business.phone
    )

    expect(call_log.twilio_call_sid).to be_nil
    expect(call_log.direction).to eq("outbound")
  end
end
