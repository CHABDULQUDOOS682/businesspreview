require "rails_helper"

RSpec.describe Billing::InvoiceLifecycleService do
  let(:business) { create(:business, subscription: true, sold_price: 500, subscription_fee: 99) }
  let(:invoice) { create(:payment_invoice, business: business, kind: "one_time", amount_cents: 50_000, status: "invoice_sent") }
  let(:service) { described_class.new(invoice) }

  describe "#handle_paid!" do
    it "starts the subscription billing cycle after the sold-price invoice is paid" do
      paid_at = Time.zone.parse("2026-07-01 12:00:00")

      service.handle_paid!(paid_at: paid_at)

      expect(business.reload).to have_attributes(
        sold_price_paid_at: paid_at,
        subscription_billing_anchor_at: paid_at,
        subscription_payment_status: "current"
      )
      expect(business.next_subscription_invoice_at).to be_within(1.second).of(paid_at + 30.days)
    end
  end

  describe "#handle_unpaid_state!" do
    let(:invoice) do
      create(
        :payment_invoice,
        business: business,
        kind: "subscription",
        amount_cents: 9_900,
        status: "invoice_sent",
        sent_at: 10.days.ago
      )
    end

    it "marks the business past due after the invoice due date" do
      service.handle_unpaid_state!(status: "invoice_sent")

      expect(business.reload.subscription_payment_status).to eq("past_due")
      expect(business.subscription_grace_ends_at).to be_present
    end
  end
end
