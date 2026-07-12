require 'rails_helper'

RSpec.describe "StripeWebhooks", type: :request do
  let(:business) { create(:business) }
  let!(:payment_invoice) { create(:payment_invoice, business: business, stripe_invoice_id: "in_123", status: "invoice_sent") }

  describe "POST /stripe_webhooks" do
    let(:payload) do
      {
        id: "evt_123",
        type: "invoice.paid",
        data: {
          object: {
            id: "in_123",
            status: "paid",
            payment_intent: {
              latest_charge: {
                receipt_url: "https://stripe.com/receipt/123"
              }
            }
          }
        }
      }
    end
    let(:sig_header) { "t=123,v1=abc" }

    before do
      allow_any_instance_of(StripeWebhooksController).to receive(:verified_event).and_call_original
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("STRIPE_WEBHOOK_SECRET").and_return(nil)

      # Mock the retrieval of the full invoice for receipt
      allow(Stripe::Invoice).to receive(:retrieve) do |params|
        Stripe::Invoice.construct_from(
          id: "in_123",
          status: "paid",
          hosted_invoice_url: "https://invoice.stripe.com/123",
          invoice_pdf: "https://pay.stripe.com/123/pdf"
        )
      end

      # Mock PaymentIntent list for receipt URL
      allow(Stripe::PaymentIntent).to receive(:list).and_return(
        Stripe::StripeObject.construct_from(
          data: [
            {
              id: "pi_123",
              latest_charge: {
                id: "ch_123",
                receipt_url: "https://stripe.com/receipt/123"
              }
            }
          ]
        )
      )
    end

    it "returns http success and updates the invoice" do
      post webhooks_stripe_path, params: payload, headers: { "HTTP_STRIPE_SIGNATURE" => sig_header }, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("paid")
      expect(payment_invoice.paid_at).to be_present
    end

    it "returns bad_request for invalid signature" do
      allow(ENV).to receive(:[]).with("STRIPE_WEBHOOK_SECRET").and_return("secret")
      allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new("Invalid signature", "sig"))
      post webhooks_stripe_path, params: payload, headers: { "HTTP_STRIPE_SIGNATURE" => "invalid" }, as: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "handles invoice.payment_failed" do
      payload = { id: "evt_123", type: "invoice.payment_failed", data: { object: { id: "in_123", status: "open" } } }
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("opened")
    end

    it "handles unpaid subscription invoices through the lifecycle service" do
      subscription_invoice = create(
        :payment_invoice,
        business: business,
        kind: "subscription",
        stripe_invoice_id: "in_sub",
        status: "invoice_sent",
        sent_at: 10.days.ago
      )
      payload = { id: "evt_sub", type: "invoice.payment_failed", data: { object: { id: "in_sub", status: "open" } } }

      post webhooks_stripe_path, params: payload, as: :json

      expect(response).to have_http_status(:success)
      expect(business.reload.subscription_payment_status).to eq("past_due")
      expect(subscription_invoice.reload.status).to eq("opened")
    end

    it "handles invoice.voided" do
      payload = { id: "evt_123", type: "invoice.voided", data: { object: { id: "in_123", status: "void" } } }
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("void")
    end

    it "handles invoice.finalized" do
      payload = { id: "evt_123", type: "invoice.finalized", data: { object: { id: "in_123", status: "open" } } }
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("invoice_sent")
    end

    it "handles invoice.payment_succeeded" do
      payload = { id: "evt_123", type: "invoice.payment_succeeded", data: { object: { id: "in_123", status: "paid" } } }
      invoice_double = Stripe::StripeObject.construct_from(id: "in_123", status: "paid", hosted_invoice_url: "url", invoice_pdf: "pdf", amount_due: 1000, amount_paid: 1000)
      expect(Stripe::Invoice).to receive(:retrieve).and_return(invoice_double)
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("paid")
    end

    it "handles invoice.marked_uncollectible" do
      payload = { id: "evt_123", type: "invoice.marked_uncollectible", data: { object: { id: "in_123", status: "uncollectible" } } }
      post webhooks_stripe_path, params: payload, as: :json
      expect(payment_invoice.reload.status).to eq("uncollectible")
    end

    it "handles invoice.updated" do
      payload = { id: "evt_123", type: "invoice.updated", data: { object: { id: "in_123", status: "paid" } } }
      post webhooks_stripe_path, params: payload, as: :json
      expect(payment_invoice.reload.status).to eq("paid")
    end

    it "handles invoice.sent event the same as finalized" do
      payload = { id: "evt_123", type: "invoice.sent", data: { object: { id: "in_123", status: "open" } } }
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("invoice_sent")
    end

    it "preserves current status when stripe_status is open and invoice is already opened" do
      # mapped_invoice_status fallthrough: stripe_status="open", current_status="opened" -> returns current_status
      payment_invoice.update_columns(status: "opened")
      payload = { id: "evt_123", type: "invoice.updated", data: { object: { id: "in_123", status: "open" } } }
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("opened")
    end

    it "handles invoice retrieval failure" do
      payload = { id: "evt_123", type: "invoice.paid", data: { object: { id: "in_123", status: "paid" } } }
      allow(Stripe::Invoice).to receive(:retrieve).and_raise(Stripe::StripeError.new("API error"))
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("paid")
    end

    it "does nothing if invoice is not found" do
      payload = { id: "evt_123", type: "invoice.paid", data: { object: { id: "unknown", status: "paid" } } }
      expect {
        post webhooks_stripe_path, params: payload, as: :json
      }.not_to raise_error
      expect(response).to have_http_status(:success)
    end

    it "links a stripe invoice id from payment_invoice_id metadata on paid events" do
      orphan = create(
        :payment_invoice,
        business: business,
        stripe_invoice_id: nil,
        status: "invoice_sent"
      )
      payload = {
        id: "evt_meta",
        type: "invoice.paid",
        data: {
          object: {
            id: "in_from_meta",
            status: "paid",
            metadata: { payment_invoice_id: orphan.id.to_s }
          }
        }
      }

      post webhooks_stripe_path, params: payload, as: :json

      expect(response).to have_http_status(:success)
      expect(orphan.reload.stripe_invoice_id).to eq("in_from_meta")
      expect(orphan.status).to eq("paid")
    end

    it "returns nil when metadata references a missing business" do
      payload = {
        id: "evt_123",
        type: "invoice.paid",
        data: { object: { id: "in_missing", status: "paid", metadata: { business_id: "999999" } } }
      }

      expect {
        post webhooks_stripe_path, params: payload, as: :json
      }.not_to raise_error
      expect(response).to have_http_status(:success)
    end

    it "reads metadata values stored with symbol keys" do
      business.update!(stripe_customer_id: "cus_meta")
      invoice = create(
        :payment_invoice,
        business: business,
        stripe_invoice_id: "in_meta",
        status: "invoice_sent"
      )
      payload = {
        id: "evt_meta",
        type: "invoice.paid",
        data: { object: { id: "in_meta", status: "paid", metadata: { business_id: business.id } } }
      }

      post webhooks_stripe_path, params: payload, as: :json

      expect(response).to have_http_status(:success)
      expect(invoice.reload.status).to eq("paid")
    end

    it "returns nil when metadata business exists but no invoice is found" do
      payload = {
        id: "evt_missing_invoice",
        type: "invoice.paid",
        data: { object: { id: "in_missing_invoice", status: "paid", metadata: { business_id: business.id } } }
      }

      expect {
        post webhooks_stripe_path, params: payload, as: :json
      }.not_to change(PaymentInvoice, :count)

      expect(response).to have_http_status(:success)
    end

    it "handles missing payment intent during receipt retrieval" do
      payload = { id: "evt_123", type: "invoice.paid", data: { object: { id: "in_123", status: "paid" } } }
      allow(Stripe::PaymentIntent).to receive(:list).and_return(double(data: []))
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.receipt_url).to be_nil
    end

    it "handles payment intent list failures during receipt retrieval" do
      payload = { id: "evt_123", type: "invoice.paid", data: { object: { id: "in_123", status: "paid" } } }
      allow(Stripe::PaymentIntent).to receive(:list).and_raise(Stripe::StripeError.new("API down"))
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
      expect(payment_invoice.reload.status).to eq("paid")
    end

    it "handles stripe_value KeyError fallbacks" do
      payload = { id: "evt_123", type: "invoice.paid", data: { object: { id: "in_123", status: "paid" } } }
      stripe_object = double("StripeInvoice", id: "in_123", blank?: false)
      allow(stripe_object).to receive(:[]).and_return(nil)
      allow(stripe_object).to receive(:respond_to?).with(anything).and_return(false)
      allow(stripe_object).to receive(:respond_to?).with(:hosted_invoice_url).and_return(true)
      allow(stripe_object).to receive(:public_send).with(:hosted_invoice_url).and_raise(KeyError.new("key"))
      allow(Stripe::Invoice).to receive(:retrieve).and_return(stripe_object)
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
    end

    it "handles stripe_value with nil object" do
      # This triggers the return nil if object.blank? in stripe_value
      payload = { id: "evt_123", type: "invoice.paid", data: { object: { id: "in_123", status: "paid" } } }
      allow(Stripe::Invoice).to receive(:retrieve).and_return(nil)
      post webhooks_stripe_path, params: payload, as: :json
      expect(response).to have_http_status(:success)
    end
  end
end
