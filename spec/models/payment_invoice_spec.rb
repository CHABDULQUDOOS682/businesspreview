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

    it "returns sold price for one-time invoices" do
      business.update(sold_price: 250)

      expect(PaymentInvoice.default_amount_for(business, "one_time")).to eq(25_000)
    end
  end

  describe "#due_at and #overdue?" do
    it "returns nil when the invoice has not been sent" do
      invoice = build(:payment_invoice, sent_at: nil)
      expect(invoice.due_at).to be_nil
      expect(invoice.overdue?).to be(false)
    end

    it "marks unpaid invoices as overdue after the due date" do
      invoice = build(:payment_invoice, status: "invoice_sent", sent_at: 10.days.ago)
      expect(invoice.due_at).to be_within(1.second).of(3.days.ago)
      expect(invoice.overdue?).to be(true)
    end
  end

  describe "#safe_hosted_invoice_url" do
    it "allows only trusted Stripe hosts" do
      invoice = build(:payment_invoice, hosted_invoice_url: "https://invoice.stripe.com/test")
      expect(invoice.safe_hosted_invoice_url).to eq("https://invoice.stripe.com/test")

      invoice.hosted_invoice_url = "https://evil.example/invoice"
      expect(invoice.safe_hosted_invoice_url).to be_nil

      invoice.hosted_invoice_url = "not a valid uri"
      expect(invoice.safe_hosted_invoice_url).to be_nil
    end
  end

  describe "validations" do
    it "requires a business email for email delivery" do
      business.update!(email: nil)
      invoice = build(:payment_invoice, business: business, delivery_method: "email")

      expect(invoice).not_to be_valid
      expect(invoice.errors[:delivery_method]).to include("requires a business email")
    end

    it "requires a business phone for sms delivery" do
      business.update_columns(phone: nil)
      invoice = build(:payment_invoice, business: business, delivery_method: "sms")

      expect(invoice).not_to be_valid
      expect(invoice.errors[:delivery_method]).to include("requires a business phone number")
    end
  end

  describe "commission creation" do
    it "logs commission creation failures without raising" do
      invoice = create(:payment_invoice, business: business, status: "invoice_sent")
      allow(Commission).to receive(:build_for_paid_invoice!).and_raise(StandardError, "boom")
      expect(Rails.logger).to receive(:error).with(/failed to build for invoice/)

      invoice.update!(status: "paid", paid_at: Time.current)
    end
  end
end
