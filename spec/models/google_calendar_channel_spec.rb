require "rails_helper"

RSpec.describe GoogleCalendarChannel, type: :model do
  it "is valid with default attributes" do
    expect(build(:google_calendar_channel)).to be_valid
  end

  it "requires channel_id, resource_id, and expires_at" do
    channel = build(:google_calendar_channel, channel_id: nil, resource_id: nil, expires_at: nil)
    expect(channel).not_to be_valid
  end

  describe "#expired?" do
    it "returns true when expires_at is blank" do
      channel = build(:google_calendar_channel, expires_at: nil)
      expect(channel.expired?).to be(true)
    end

    it "returns true when expires_at is in the past" do
      channel = build(:google_calendar_channel, expires_at: 1.hour.ago)
      expect(channel.expired?).to be(true)
    end

    it "returns false when expires_at is in the future" do
      channel = build(:google_calendar_channel, expires_at: 1.hour.from_now)
      expect(channel.expired?).to be(false)
    end
  end

  describe ".active" do
    it "includes channels that have not expired" do
      active = create(:google_calendar_channel, expires_at: 1.day.from_now)
      create(:google_calendar_channel, expires_at: 1.day.ago)

      expect(described_class.active).to contain_exactly(active)
    end
  end
end
