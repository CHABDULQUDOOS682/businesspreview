# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhoneLookupJob, type: :job do
  let(:business) { create(:business, phone: "+16232481437") }

  it "stores landline when phonelib classifies as fixed_line" do
    parsed = instance_double(Phonelib::Phone, valid?: true, possible?: true, type: :fixed_line)
    allow(Phonelib).to receive(:parse).with(business.phone).and_return(parsed)

    described_class.perform_now(business.id)

    business.reload
    expect(business.phone_line_type).to eq("landline")
    expect(business.phone_lookup_checked_at).to be_present
    expect(business.phone_lookup_error).to be_nil
  end

  it "stores mobile when phonelib classifies as mobile" do
    parsed = instance_double(Phonelib::Phone, valid?: true, possible?: true, type: :mobile)
    allow(Phonelib).to receive(:parse).with(business.phone).and_return(parsed)

    described_class.perform_now(business.id)

    expect(business.reload.phone_line_type).to eq("mobile")
  end

  it "stores an error when the number is invalid" do
    parsed = instance_double(Phonelib::Phone, valid?: false, possible?: false, type: :unknown)
    allow(Phonelib).to receive(:parse).with(business.phone).and_return(parsed)

    described_class.perform_now(business.id)

    business.reload
    expect(business.phone_lookup_checked_at).to be_present
    expect(business.phone_lookup_error).to eq("Invalid phone number")
    expect(business.phone_line_type).to be_nil
  end

  it "returns early when the business has no phone" do
    business.update_columns(phone: "")

    expect(Phonelib).not_to receive(:parse)
    described_class.perform_now(business.id)

    expect(business.reload.phone_lookup_checked_at).to be_nil
  end

  it "no-ops when the business no longer exists" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
