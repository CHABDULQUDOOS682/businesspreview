require "rails_helper"

RSpec.describe Admin::BusinessesHelper, type: :helper do
  let(:business) { create(:business) }

  describe "#business_payment_status_badge" do
    it "returns 'No Invoice' if no invoice exists" do
      expect(helper.business_payment_status_badge(business)).to include("No Invoice")
    end

    it "returns a green badge for paid status" do
      create(:payment_invoice, business: business, status: "paid")
      expect(helper.business_payment_status_badge(business)).to include("bg-green-50")
      expect(helper.business_payment_status_badge(business)).to include("Paid")
    end

    it "returns 'Pending' for opened status" do
      create(:payment_invoice, business: business, status: "opened")
      expect(helper.business_payment_status_badge(business)).to include("Pending")
    end

    it "returns badge for invoice_sent status" do
      create(:payment_invoice, business: business, status: "invoice_sent")
      expect(helper.business_payment_status_badge(business)).to include("Invoice Sent")
    end

    it "returns badge for draft status" do
      create(:payment_invoice, business: business, status: "draft")
      expect(helper.business_payment_status_badge(business)).to include("Draft")
    end

    it "returns badge for failed status" do
      create(:payment_invoice, business: business, status: "failed")
      expect(helper.business_payment_status_badge(business)).to include("Failed")
    end

    it "returns default badge for unknown status" do
      create(:payment_invoice, business: business, status: "void")
      expect(helper.business_payment_status_badge(business)).to include("bg-slate-50")
    end
  end
end
