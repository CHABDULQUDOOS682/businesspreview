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

    it "updates receipt url" do
      stripe_invoice = double("stripe_invoice", id: "in_123", status: "paid", amount_due: 1000, amount_paid: 1000, hosted_invoice_url: "url", invoice_pdf: "pdf")
      invoice.store_paid_documents!(stripe_invoice: stripe_invoice, receipt_url: "receipt_url")

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

  describe "#safe_hosted_invoice_url" do
    let(:invoice) { build(:payment_invoice, business: business) }

    it "returns nil if blank" do
      invoice.hosted_invoice_url = nil
      expect(invoice.safe_hosted_invoice_url).to be_nil
    end

    it "returns url if valid and allowed" do
      invoice.hosted_invoice_url = "https://invoice.stripe.com/abc"
      expect(invoice.safe_hosted_invoice_url).to eq("https://invoice.stripe.com/abc")
    end

    it "returns nil if host not allowed" do
      invoice.hosted_invoice_url = "https://malicious.com/abc"
      expect(invoice.safe_hosted_invoice_url).to be_nil
    end

    it "returns nil if invalid URI" do
      invoice.hosted_invoice_url = "https:// invalid.com"
      expect(invoice.safe_hosted_invoice_url).to be_nil
    end
  end

  describe "internal helper methods" do
    let(:invoice) { create(:payment_invoice, business: business) }

    it "default_amount_for returns nil if blank" do
      business.update_columns(sold_price: nil, subscription_fee: nil)
      expect(PaymentInvoice.default_amount_for(business, "one_time")).to be_nil
    end

    it "mark_opened! sets status and timestamp" do
      expect { invoice.mark_opened! }.to change { invoice.status }.to("opened")
      expect(invoice.opened_at).not_to be_nil
    end

    it "mark_opened! returns early if already paid" do
      invoice.update_columns(status: "paid")
      expect { invoice.mark_opened! }.not_to(change { invoice.opened_at })
    end

    it "status_label formats properly" do
      invoice.status = "invoice_sent"
      expect(invoice.status_label).to eq("Invoice Sent")
      invoice.status = "paid"
      expect(invoice.status_label).to eq("Paid")
    end
  end
end
