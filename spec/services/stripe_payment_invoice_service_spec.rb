require "rails_helper"

RSpec.describe StripePaymentInvoiceService do
  let(:business) { create(:business, phone: "+1234567890", email: "client@example.com") }
  let(:payment_invoice) { create(:payment_invoice, business: business, delivery_method: "email_and_sms") }
  let(:service) { StripePaymentInvoiceService.new(payment_invoice) }

  before do
    allow(Stripe).to receive(:api_key).and_return("sk_test_123")
  end

  describe "#create_and_send!" do
    let(:customer_mock) { double("stripe_customer", id: "cus_123") }
    let(:invoice_mock) { double("stripe_invoice", id: "in_123", status: "open", customer: "cus_123", hosted_invoice_url: "https://stripe.com/inv", invoice_pdf: "https://stripe.com/pdf") }

    before do
      allow(Stripe::Customer).to receive(:create).and_return(customer_mock)
      allow(Stripe::Invoice).to receive(:create).and_return(invoice_mock)
      allow(Stripe::InvoiceItem).to receive(:create)
      allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(invoice_mock)
      allow(SmsService).to receive(:send_sms)
      allow(PaymentInvoiceMailer).to receive_message_chain(:with, :invoice_link, :deliver_now)
    end

    it "creates a customer and an invoice successfully" do
      service.create_and_send!
      
      expect(payment_invoice.reload.status).to eq("invoice_sent")
      expect(payment_invoice.stripe_invoice_id).to eq("in_123")
      expect(SmsService).to have_received(:send_sms)
      expect(payment_invoice.business.stripe_customer_id).to eq("cus_123")
    end

    context "when kind is subscription" do
      let(:payment_invoice) { create(:payment_invoice, kind: "subscription", business: business) }
      let(:product_mock) { double("stripe_product", id: "prod_123") }
      let(:price_mock) { double("stripe_price", id: "price_123") }
      let(:subscription_mock) { double("stripe_subscription", id: "sub_123", latest_invoice: "in_draft") } # Test string retrieval

      before do
        allow(Stripe::Product).to receive(:create).and_return(product_mock)
        allow(Stripe::Price).to receive(:create).and_return(price_mock)
        allow(Stripe::Subscription).to receive(:create).and_return(subscription_mock)
        allow(Stripe::Invoice).to receive(:retrieve).and_return(double("stripe_invoice", id: "in_draft", status: "draft", customer: "cus_123", hosted_invoice_url: "url", invoice_pdf: "pdf"))
        allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(invoice_mock)
      end

      it "creates a subscription and associated objects" do
        service.create_and_send!
        expect(payment_invoice.reload.stripe_subscription_id).to eq("sub_123")
      end
    end

    context "when configuration is missing" do
      before { allow(Stripe).to receive(:api_key).and_return(nil) }

      it "raises ConfigurationError" do
        expect { service.create_and_send! }.to raise_error(StripePaymentInvoiceService::ConfigurationError)
      end
    end

    context "when delivery fails" do
      let(:failed_invoice_mock) { double("stripe_invoice", id: "in_123", status: "open", customer: "cus_123", hosted_invoice_url: nil, invoice_pdf: nil) }

      it "raises error if hosted_invoice_url is blank" do
        allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(failed_invoice_mock)
        expect { service.create_and_send! }.to raise_error(StripePaymentInvoiceService::ConfigurationError, /Stripe did not return/)
      end

      it "handles SMS service errors" do
        allow(SmsService).to receive(:send_sms).and_raise(StandardError.new("Twilio error"))
        expect { service.create_and_send! }.to raise_error(StripePaymentInvoiceService::ConfigurationError, /SMS Error/)
      end

      it "handles Mailer errors" do
        allow(PaymentInvoiceMailer).to receive_message_chain(:with, :invoice_link, :deliver_now).and_raise(StandardError.new("SMTP error"))
        expect { service.create_and_send! }.to raise_error(StripePaymentInvoiceService::ConfigurationError, /Email Error/)
      end
    end

    context "when invoice is already paid" do
      let(:paid_invoice_mock) { double("stripe_invoice", id: "in_123", status: "paid", customer: "cus_123", hosted_invoice_url: "url", invoice_pdf: "pdf") }
      
      before do
        allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(paid_invoice_mock)
      end

      it "sets status to paid" do
        service.create_and_send!
        expect(payment_invoice.reload.status).to eq("paid")
      end
    end

    context "when Stripe raises an error" do
      before do
        allow(Stripe::Invoice).to receive(:create).and_raise(Stripe::StripeError.new("API Error"))
      end

      it "updates status to failed and re-raises" do
        expect { service.create_and_send! }.to raise_error(Stripe::StripeError)
        expect(payment_invoice.reload.status).to eq("failed")
        expect(payment_invoice.last_error).to eq("API Error")
      end
    end

    context "when delivery method is sms only" do
      let(:payment_invoice) { create(:payment_invoice, business: business, delivery_method: "sms") }
      let(:service) { StripePaymentInvoiceService.new(payment_invoice) }

      before do
        allow(Stripe::Customer).to receive(:create).and_return(customer_mock)
        allow(Stripe::Invoice).to receive(:create).and_return(invoice_mock)
        allow(Stripe::InvoiceItem).to receive(:create)
        allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(invoice_mock)
        allow(SmsService).to receive(:send_sms)
        allow(Message).to receive(:create!)
      end

      it "skips email and followup job but sends sms" do
        expect(PaymentInvoiceMailer).not_to receive(:with)
        expect(PaymentInvoiceFollowupJob).not_to receive(:set)
        service.create_and_send!
        expect(SmsService).to have_received(:send_sms)
      end
    end
  end

  describe "stripe object value extraction" do
    it "reads values from hash-like objects when no reader method is available" do
      value = service.send(:stripe_object_value, { "hosted_invoice_url" => "https://stripe.test/invoice" }, :hosted_invoice_url)

      expect(value).to eq("https://stripe.test/invoice")
    end
  end
end
