require 'rails_helper'

RSpec.describe Business, type: :model do
  describe "validations" do
    it "requires a phone number" do
      business = build(:business, phone: nil)

      expect(business).not_to be_valid
      expect(business.errors[:phone]).to include("can't be blank")
    end

    it "normalizes phone numbers before validation" do
      business = build(:business, phone: " (123) 456-7890 ")

      business.valid?

      expect(business.phone).to eq("+1234567890")
    end

    it "normalizes a leading plus and removes formatting" do
      business = build(:business, phone: "+1.234.567.890")

      business.valid?

      expect(business.phone).to eq("+1234567890")
    end

    it "treats differently formatted copies of the same phone as duplicates" do
      create(:business, phone: "+1 (800) 555-0199")

      duplicate = build(:business, phone: "1-800-555-0199")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:phone]).to include("has already been taken")
    end
  end

  describe "scopes" do
    it "filters task sources" do
      create(:business, task_source_enabled: true, task_base_url: "http://api.com", task_secret: "secret")
      create(:business, task_source_enabled: false)
      expect(Business.task_sources.count).to eq(1)
    end

    it "filters nurture pipeline" do
      create(:business, sold_price: nil, subscription_fee: nil)
      expect(Business.nurture_pipeline.count).to eq(1)
    end

    it "filters purchased pipeline" do
      create(:business, sold_price: 100, subscription_fee: nil)
      expect(Business.purchased_pipeline.count).to eq(1)
    end

    it "filters subscriptions pipeline" do
      create(:business, subscription: true)
      expect(Business.subscriptions_pipeline.count).to eq(1)
    end
  end

  describe "class methods" do
    it "normalizes segments" do
      expect(Business.normalize_segment("purchased")).to eq("purchased")
      expect(Business.normalize_segment("invalid")).to eq("nurture")
    end

    it "returns segment counts" do
      create(:business, sold_price: 100, subscription_fee: nil)
      counts = Business.segment_counts
      expect(counts["purchased"]).to eq(1)
    end
  end

  describe "instance methods" do
    it "returns business segment" do
      business = build(:business, subscription: true)
      expect(business.business_segment).to eq("subscriptions")

      business.subscription = false
      business.subscription_fee = nil
      business.sold_price = 100
      expect(business.business_segment).to eq("purchased")

      business.sold_price = nil
      expect(business.business_segment).to eq("nurture")
    end

    it "returns task source name" do
      business = build(:business, name: "Acme", website_name: "Acme Web")
      expect(business.task_source_name).to eq("Acme Web")

      business.website_name = nil
      expect(business.task_source_name).to eq("Acme")
    end

    it "generates a review token before create" do
      business = create(:business, review_token: nil)
      expect(business.review_token).not_to be_nil
    end

    it "returns a valid review_url" do
      business = create(:business)
      expect(business.review_url).to include("/reviews/new/")
      expect(business.review_url).to include(business.review_token)
    end
  end
end
