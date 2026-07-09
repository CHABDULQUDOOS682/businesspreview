require "rails_helper"

RSpec.describe PaymentInvoice, type: :model do
  let(:business) { create(:business, email: "client@example.com", phone: "+1234567890") }

  describe ".build_for_business" do
    it "builds a manual sold-price invoice for subscription businesses awaiting initial payment" do
      business.update(subscription: true, sold_price: 500, subscription_fee: 99)

      invoice = PaymentInvoice.build_for_business(business)

      expect(invoice.kind).to eq("one_time")
      expect(invoice.amount_cents).to eq(50_000)
      expect(invoice.manual_send_available?).to be(true)
    end

    it "does not offer a manual invoice after sold price is collected" do
      business.update(subscription: true, sold_price: 500, subscription_fee: 99, sold_price_paid_at: Time.current)

      invoice = PaymentInvoice.build_for_business(business)

      expect(invoice.manual_send_available?).to be(false)
      expect(invoice.amount_cents).to eq(0)
    end

    it "builds a one-time sold-price invoice for purchased websites" do
      business.update(subscription: false, subscription_fee: nil, sold_price: 500)

      invoice = PaymentInvoice.build_for_business(business)

      expect(invoice.kind).to eq("one_time")
      expect(invoice.amount_cents).to eq(50_000)
    end
  end

  describe ".default_amount_for" do
    it "returns subscription fee for subscription invoices" do
      business.update(subscription: true, subscription_fee: 99)

      expect(PaymentInvoice.default_amount_for(business, "subscription")).to eq(9_900)
    end
  end
end
