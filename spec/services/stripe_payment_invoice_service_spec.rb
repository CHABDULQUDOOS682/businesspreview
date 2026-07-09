require "rails_helper"

RSpec.describe StripePaymentInvoiceService do
  let(:business) { create(:business, phone: "+1234567890", email: "client@example.com") }
  let(:payment_invoice) { create(:payment_invoice, business: business, delivery_method: "email_and_sms") }
  let(:service) { StripePaymentInvoiceService.new(payment_invoice) }
  let(:customer_mock) { Stripe::StripeObject.construct_from(id: "cus_123") }
  let(:invoice_mock) { Stripe::StripeObject.construct_from(id: "in_123", status: "open", customer: "cus_123", hosted_invoice_url: "https://stripe.com/inv", invoice_pdf: "https://stripe.com/pdf") }

  before do
    allow(Stripe).to receive(:api_key).and_return("sk_test_123")
    allow(Stripe::Customer).to receive(:create).and_return(customer_mock)
    allow(Stripe::Invoice).to receive(:create).and_return(invoice_mock)
    allow(Stripe::InvoiceItem).to receive(:create)
    allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(invoice_mock)
    allow(SmsService).to receive(:send_sms)
    allow(PaymentInvoiceMailer).to receive_message_chain(:with, :invoice_link, :deliver_later)
  end

  describe "#create_and_send!" do
    it "creates a hosted invoice for both one-time and subscription fee invoices" do
      service.create_and_send!

      expect(Stripe::InvoiceItem).to have_received(:create).with(hash_including(amount: payment_invoice.amount_cents))
      expect(payment_invoice.reload.status).to eq("invoice_sent")
    end

    it "marks the invoice failed and re-raises Stripe errors" do
      allow(Stripe::Invoice).to receive(:create).and_raise(Stripe::StripeError.new("Stripe down"))

      expect { service.create_and_send! }.to raise_error(Stripe::StripeError, "Stripe down")
      expect(payment_invoice.reload.status).to eq("failed")
      expect(payment_invoice.last_error).to eq("Stripe down")
    end

    it "raises when Stripe invoice attributes cannot be persisted" do
      errors = payment_invoice.errors
      allow(payment_invoice).to receive(:update).and_call_original
      allow(payment_invoice).to receive(:update).with(hash_including(:stripe_invoice_id)).and_return(false)
      allow(payment_invoice).to receive(:errors).and_return(errors)

      expect { service.create_and_send! }.to raise_error(
        StripePaymentInvoiceService::ConfigurationError,
        /Failed to update invoice/
      )
    end

    it "wraps SMS delivery failures" do
      payment_invoice.update!(delivery_method: "sms")
      allow(SmsService).to receive(:send_sms).and_raise(StandardError.new("SMS gateway down"))

      expect { service.create_and_send! }.to raise_error(
        StripePaymentInvoiceService::ConfigurationError,
        "SMS Error: SMS gateway down"
      )
    end

    it "wraps email delivery failures" do
      allow(PaymentInvoiceMailer).to receive_message_chain(:with, :invoice_link, :deliver_later)
        .and_raise(StandardError.new("mailer down"))

      expect { service.create_and_send! }.to raise_error(
        StripePaymentInvoiceService::ConfigurationError,
        "Email Error: mailer down"
      )
    end
  end

  describe "#stripe_object_value" do
    it "falls back to public_send and returns nil when access fails" do
      stripe_object = double("StripeObject", blank?: false)
      allow(stripe_object).to receive(:[]).and_return(nil)
      allow(stripe_object).to receive(:respond_to?).with(anything).and_return(false)
      allow(stripe_object).to receive(:respond_to?).with(:customer).and_return(true)
      allow(stripe_object).to receive(:public_send).with(:customer).and_raise(StandardError, "boom")

      expect(service.send(:stripe_object_value, stripe_object, :customer)).to be_nil
    end

    it "returns nil when the object does not respond to the key" do
      expect(service.send(:stripe_object_value, Object.new, :missing)).to be_nil
    end
  end
end
