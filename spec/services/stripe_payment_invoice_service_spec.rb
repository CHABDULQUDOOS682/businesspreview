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
  end
end
