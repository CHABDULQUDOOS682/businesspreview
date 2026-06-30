require "rails_helper"

RSpec.describe BusinessCommissionRate, type: :model do
  describe "validations" do
    it "is valid with proper attributes" do
      rate = build(:business_commission_rate)
      expect(rate).to be_valid
    end

    it "enforces uniqueness on business_id, kind, and month_number" do
      business = create(:business)
      create(:business_commission_rate, business: business, kind: "subscription", month_number: 1)
      duplicate = build(:business_commission_rate, business: business, kind: "subscription", month_number: 1)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".rate_for" do
    it "returns the business's specific rate override" do
      business = create(:business)
      create(:business_commission_rate, business: business, kind: "subscription", month_number: 1, percentage: 11.5)
      expect(described_class.rate_for(business, "subscription", 1)).to eq(11.5)
    end
  end
end
