require "rails_helper"

RSpec.describe Admin::MeetingsCalendar do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2026, 7, 1, 9, 0)) { example.run }
  end

  let(:month) { Date.new(2026, 7, 1) }
  let(:employee) { create(:user, role: "employee") }
  let(:business) { create(:business) }
  let!(:meeting) do
    create(
      :meeting,
      user: employee,
      business: business,
      starts_at: Time.zone.local(2026, 7, 15, 10, 0)
    )
  end
  let(:calendar) { described_class.new(month: month, meetings: Meeting.all) }

  describe "#weeks" do
    it "returns weeks padded to full calendar grid" do
      weeks = calendar.weeks
      expect(weeks.first.size).to eq(7)
      expect(weeks.flatten.compact).to include(Date.new(2026, 7, 15))
    end
  end

  describe "#meetings_on" do
    it "returns meetings for the given date" do
      expect(calendar.meetings_on(Date.new(2026, 7, 15))).to eq([ meeting ])
    end

    it "returns an empty array when there are no meetings" do
      expect(calendar.meetings_on(Date.new(2026, 7, 1))).to eq([])
    end
  end

  describe "#meeting_count_on" do
    it "returns the number of meetings on a date" do
      expect(calendar.meeting_count_on(Date.new(2026, 7, 15))).to eq(1)
      expect(calendar.meeting_count_on(Date.new(2026, 7, 1))).to eq(0)
    end
  end
end
