require "rails_helper"

RSpec.describe EmployeeCommissionRate, type: :model do
  describe "validations" do
    it "is valid with proper attributes" do
      rate = build(:employee_commission_rate)
      expect(rate).to be_valid
    end

    it "enforces uniqueness on user_id, kind, and month_number" do
      user = create(:user)
      create(:employee_commission_rate, user: user, kind: "subscription", month_number: 1)
      duplicate = build(:employee_commission_rate, user: user, kind: "subscription", month_number: 1)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".rate_for" do
    it "returns the user's specific rate" do
      user = create(:user)
      create(:employee_commission_rate, user: user, kind: "subscription", month_number: 1, percentage: 9.5)
      expect(described_class.rate_for(user, "subscription", 1)).to eq(9.5)
    end
  end

  describe ".upsert_rate!" do
    it "creates a new rate if none exists" do
      user = create(:user)
      expect {
        described_class.upsert_rate!(user: user, kind: "subscription", month_number: 1, percentage: 7.5)
      }.to change(described_class, :count).by(1)

      rate = described_class.last
      expect(rate.percentage).to eq(7.5)
    end

    it "updates an existing rate if it exists" do
      user = create(:user)
      rate = create(:employee_commission_rate, user: user, kind: "subscription", month_number: 1, percentage: 6.0)

      expect {
        described_class.upsert_rate!(user: user, kind: "subscription", month_number: 1, percentage: 8.5)
      }.not_to change(described_class, :count)

      expect(rate.reload.percentage).to eq(8.5)
    end
  end
end
