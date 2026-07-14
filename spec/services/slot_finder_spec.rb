require "rails_helper"

RSpec.describe SlotFinder, type: :service do
  let(:owner) { create(:user, :super_admin) }
  let(:other_user) { create(:user, role: "employee") }
  let(:date) { Date.new(2026, 7, 22) } # Wednesday

  before do
    AvailabilityRule.create!(
      user: owner,
      day_of_week: 3,
      start_minute: 540,  # 9:00 AM
      end_minute: 660     # 11:00 AM
    )
  end

  describe "#slots_for" do
    it "returns list of slots" do
      slots = SlotFinder.new(user: owner).slots_for(date)
      expect(slots.size).to eq(4)
      expect(slots[0]).to eq(date.in_time_zone.change(hour: 9, min: 0))
      expect(slots[1]).to eq(date.in_time_zone.change(hour: 9, min: 30))
      expect(slots[2]).to eq(date.in_time_zone.change(hour: 10, min: 0))
      expect(slots[3]).to eq(date.in_time_zone.change(hour: 10, min: 30))
    end

    it "excludes overlapping slots for any user (company-wide)" do
      business = create(:business)
      Meeting.create!(
        user: other_user,
        business: business,
        client_name: "Test Client",
        client_email: "client@example.com",
        title: "Meeting",
        starts_at: date.in_time_zone.change(hour: 9, min: 30),
        duration_minutes: 30
      )

      slots = SlotFinder.new(user: owner).slots_for(date)
      expect(slots.size).to eq(3)
      expected_times = [
        date.in_time_zone.change(hour: 9, min: 0),
        date.in_time_zone.change(hour: 10, min: 0),
        date.in_time_zone.change(hour: 10, min: 30)
      ]
      expect(slots).to eq(expected_times)
    end

    it "keeps the current meeting slot when excluding_id is provided" do
      business = create(:business)
      meeting = Meeting.create!(
        user: owner,
        business: business,
        client_name: "Test Client",
        client_email: "client@example.com",
        title: "Meeting",
        starts_at: date.in_time_zone.change(hour: 9, min: 30),
        duration_minutes: 30
      )

      slots = SlotFinder.new(user: owner, excluding_id: meeting.id).slots_for(date)
      expect(slots).to include(date.in_time_zone.change(hour: 9, min: 30))
    end
  end
end
