require "rails_helper"

RSpec.describe AvailabilityRule, type: :model do
  let(:user) { create(:user) }

  it "is valid with valid attributes" do
    rule = AvailabilityRule.new(user: user, day_of_week: 1, start_minute: 540, end_minute: 1020)
    expect(rule).to be_valid
  end

  it "requires start_minute and end_minute" do
    rule = AvailabilityRule.new(user: user, day_of_week: 1)
    expect(rule).not_to be_valid
  end

  it "validates that end_minute is after start_minute" do
    rule = AvailabilityRule.new(user: user, day_of_week: 1, start_minute: 600, end_minute: 600)
    expect(rule).not_to be_valid
    expect(rule.errors[:end_minute]).to include("must be after start time")
  end

  it "validates day_of_week inclusion in 0..6" do
    rule = AvailabilityRule.new(user: user, day_of_week: 7, start_minute: 540, end_minute: 1020)
    expect(rule).not_to be_valid
  end

  describe "time calculation helpers" do
    let(:date) { Date.new(2026, 7, 15) } # A Wednesday
    let(:rule) { AvailabilityRule.new(user: user, day_of_week: 3, start_minute: 540, end_minute: 1020) }

    it "returns correct start time" do
      expect(rule.start_time_on(date)).to eq(date.in_time_zone.beginning_of_day + 9.hours)
    end

    it "returns correct end time" do
      expect(rule.end_time_on(date)).to eq(date.in_time_zone.beginning_of_day + 17.hours)
    end
  end
end
