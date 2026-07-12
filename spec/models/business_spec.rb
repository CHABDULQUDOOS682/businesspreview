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

    it "generates a review token before create" do
      business = create(:business, review_token: nil)
      expect(business.review_token).not_to be_nil
    end

    it "returns a valid review_url" do
      business = create(:business)
      expect(business.review_url).to include("/reviews/new/")
      expect(business.review_url).to include(business.review_token)
    end

    describe "subscription billing helpers" do
      let(:business) { create(:business, subscription: true, sold_price: 500, subscription_fee: 99) }

      it "detects the first subscription invoice" do
        expect(business.subscription_first_invoice?).to be(true)

        invoice = create(:payment_invoice, business: business, kind: "subscription", status: "invoice_sent")
        expect(business.subscription_first_invoice?).to be(false)
        expect(business.subscription_first_invoice?(excluding: invoice)).to be(true)
      end

      it "reports subscription payment status helpers" do
        business.update!(subscription_payment_status: "current")
        expect(business.subscription_payment_current?).to be(true)
        expect(business.subscription_payment_past_due?).to be(false)
        expect(business.subscription_suspended?).to be(false)

        business.update!(subscription_payment_status: "past_due")
        expect(business.subscription_payment_past_due?).to be(true)

        business.update!(subscription_payment_status: "suspended")
        expect(business.subscription_suspended?).to be(true)
      end

      it "activates subscription billing when prerequisites are met" do
        business.update!(sold_price_paid_at: Time.current)
        anchor = Time.zone.parse("2026-07-01 12:00:00")

        business.activate_subscription_billing!(anchor_at: anchor)

        expect(business.reload).to have_attributes(
          subscription_billing_anchor_at: anchor,
          subscription_payment_status: "current"
        )
        expect(business.next_subscription_invoice_at).to be_within(1.second).of(anchor + 30.days)
      end

      it "skips activation when prerequisites are missing" do
        non_subscription = create(:business, subscription: false)
        expect { non_subscription.activate_subscription_billing! }.not_to change { non_subscription.reload.subscription_billing_anchor_at }

        unpaid = create(:business, subscription: true, sold_price: 500, subscription_fee: 99)
        expect { unpaid.activate_subscription_billing! }.not_to change { unpaid.reload.subscription_billing_anchor_at }

        no_fee = create(:business, subscription: true, sold_price_paid_at: Time.current, subscription_fee: nil)
        expect { no_fee.activate_subscription_billing! }.not_to change { no_fee.reload.subscription_billing_anchor_at }
      end
    end
  end
end
