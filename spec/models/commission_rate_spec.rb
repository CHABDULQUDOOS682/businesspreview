require "rails_helper"

RSpec.describe CommissionRate, type: :model do
  describe "validations" do
    it "is valid with proper attributes" do
      rate = build(:commission_rate, kind: "one_time", month_number: nil, percentage: 10.0)
      expect(rate).to be_valid
    end

    it "requires kind to be in KINDS" do
      rate = build(:commission_rate, kind: "invalid")
      expect(rate).not_to be_valid
    end

    it "requires percentage to be between 0 and 100" do
      rate1 = build(:commission_rate, percentage: -1)
      rate2 = build(:commission_rate, percentage: 101)
      expect(rate1).not_to be_valid
      expect(rate2).not_to be_valid
    end

    it "requires month_number to be present if subscription" do
      rate = build(:commission_rate, kind: "subscription", month_number: nil)
      expect(rate).not_to be_valid
    end

    it "requires month_number to be nil if one_time" do
      rate = build(:commission_rate, kind: "one_time", month_number: 1)
      expect(rate).not_to be_valid
    end

    it "enforces uniqueness on kind and month_number" do
      create(:commission_rate, kind: "subscription", month_number: 1, percentage: 8.0)
      duplicate = build(:commission_rate, kind: "subscription", month_number: 1, percentage: 5.0)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".default_for" do
    it "returns percentage for a given kind and month_number" do
      create(:commission_rate, kind: "subscription", month_number: 2, percentage: 4.5)
      expect(described_class.default_for("subscription", 2)).to eq(4.5)
      expect(described_class.default_for("subscription", 3)).to be_nil
    end
  end
end
