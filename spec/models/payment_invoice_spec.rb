require "rails_helper"

RSpec.describe PaymentInvoice, type: :model do
  let(:business) { create(:business, email: "client@example.com", phone: "+1234567890") }

  describe ".build_for_business" do
    it "sets kind to one_time by default" do
      business.update(subscription_fee: nil, subscription: false)
      invoice = PaymentInvoice.build_for_business(business)
      expect(invoice.kind).to eq("one_time")
    end

    it "sets kind to subscription if active" do
      business.update(subscription: true)
      invoice = PaymentInvoice.build_for_business(business)
      expect(invoice.kind).to eq("subscription")
    end

    it "sets correct delivery method" do
      expect(PaymentInvoice.build_for_business(business).delivery_method).to eq("email_and_sms")
      business.update(phone: nil)
      expect(PaymentInvoice.build_for_business(business).delivery_method).to eq("email")
    end
  end

  describe "#store_paid_documents!" do
    let(:invoice) { create(:payment_invoice, business: business) }

    it "updates snapshots and receipt url" do
      stripe_invoice = double("stripe_invoice", id: "in_123", status: "paid", amount_due: 1000, amount_paid: 1000, hosted_invoice_url: "url", invoice_pdf: "pdf")
      invoice.store_paid_documents!(stripe_invoice: stripe_invoice, receipt_url: "receipt_url")
      
      expect(invoice.invoice_snapshot_html).to include("in_123")
      expect(invoice.receipt_snapshot_html).to include("receipt_url")
      expect(invoice.receipt_url).to eq("receipt_url")
    end
  end

  describe "validations" do
    it "validates currency length" do
      invoice = build(:payment_invoice, currency: "us")
      expect(invoice).not_to be_valid
    end

    it "validates business has requested destination" do
      business.update_columns(email: nil)
      invoice = build(:payment_invoice, business: business, delivery_method: "email")
      expect(invoice).not_to be_valid
    end
  end
end
