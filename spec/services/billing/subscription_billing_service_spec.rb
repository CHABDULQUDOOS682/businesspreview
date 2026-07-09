# frozen_string_literal: true

require "rails_helper"

RSpec.describe Billing::SubscriptionBillingService do
  let(:business) do
    create(
      :business,
      subscription: true,
      sold_price: 500,
      subscription_fee: 99,
      sold_price_paid_at: 60.days.ago,
      next_subscription_invoice_at: 1.day.ago,
      subscription_payment_status: "current",
      email: "billing@example.com"
    )
  end
  let(:service) { described_class.new(business) }
  let(:stripe_service) { instance_double(StripePaymentInvoiceService, create_and_send!: true) }

  before do
    allow(StripePaymentInvoiceService).to receive(:new).and_return(stripe_service)
  end

  describe "#create_and_send!" do
    it "creates and sends a subscription invoice when billing is due" do
      invoice = service.create_and_send!

      expect(invoice).to be_persisted
      expect(invoice.kind).to eq("subscription")
      expect(invoice.amount_cents).to eq(9_900)
      expect(stripe_service).to have_received(:create_and_send!)
      expect(business.reload.subscription_payment_status).to eq("current")
      expect(business.next_subscription_invoice_at).to be > 1.day.ago
    end

    it "raises when billing is not due" do
      business.update!(next_subscription_invoice_at: 1.week.from_now)

      expect {
        service.create_and_send!
      }.to raise_error(ArgumentError, /not due/)
    end
  end
end
