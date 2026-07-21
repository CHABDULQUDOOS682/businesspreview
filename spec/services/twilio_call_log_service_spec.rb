require "rails_helper"

RSpec.describe TwilioCallLogService do
  describe "#recent_calls" do
    let(:calls_resource) { double("CallsResource") }
    let(:client) { double("TwilioClient", calls: calls_resource) }
    let!(:business) { create(:business, name: "Northside Barber", phone: "+1 (555) 000-0002") }

    it "loads calls from Twilio and matches businesses by phone number" do
      twilio_call = double(
        "TwilioCall",
        sid: "CA123",
        from: "+15550000001",
        to: "+15550000002",
        direction: "outbound-api",
        status: "completed",
        duration: "125",
        start_time: Time.zone.local(2026, 6, 14, 10, 30),
        date_created: Time.zone.local(2026, 6, 14, 10, 29)
      )
      allow(calls_resource).to receive(:list).with(limit: 100).and_return([ twilio_call ])

      records = described_class.new(client: client).recent_calls

      expect(records.size).to eq(1)
      expect(records.first.sid).to eq("CA123")
      expect(records.first.direction).to eq("outbound")
      expect(records.first.duration_label).to eq("2:05")
      expect(records.first.business).to eq(business)
      expect(records.first.logged_at).to eq(Time.zone.local(2026, 6, 14, 10, 30))
    end

    it "normalizes inbound Twilio directions" do
      twilio_call = double(
        "TwilioCall",
        sid: "CA124",
        from: "+15550000002",
        to: "+15550000001",
        direction: "inbound",
        status: "completed",
        duration: "0",
        start_time: nil,
        date_created: Time.zone.local(2026, 6, 14, 10, 29)
      )
      allow(calls_resource).to receive(:list).with(limit: 100).and_return([ twilio_call ])

      record = described_class.new(client: client).recent_calls.first

      expect(record.direction).to eq("inbound")
      expect(record.duration_label).to eq("-")
      expect(record.direction_label).to eq("Inbound")
      expect(record.logged_at).to eq(Time.zone.local(2026, 6, 14, 10, 29))
    end
  end
end
