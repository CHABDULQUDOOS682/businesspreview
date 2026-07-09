require 'rails_helper'

RSpec.describe "Admin::PaymentInvoices", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business) }

  before do
    sign_in admin
  end

  describe "GET /admin/payment_invoices" do
    it "shows invoices across businesses with business links" do
      invoice = create(
        :payment_invoice,
        business: business,
        status: "paid",
        sent_to_email: "billing@example.com",
        stripe_invoice_id: "in_123"
      )

      get admin_payment_invoices_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("All Invoices")
      expect(response.body).to include(invoice.kind_label)
      expect(response.body).to include("billing@example.com")
      expect(response.body).to include("in_123")
      expect(response.body).to include(admin_business_path(business))
      expect(response.body).to include(business.name)
    end

    it "filters invoices by search query" do
      invoice = create(:payment_invoice, business: business, sent_to_email: "billing@example.com")
      other_invoice = create(:payment_invoice, business: create(:business, name: "Hidden Co"))

      get admin_payment_invoices_path, params: { q: business.name }

      expect(response.body).to include(invoice.business.name)
      expect(response.body).not_to include(other_invoice.business.name)
    end

    it "filters invoices by status" do
      paid_invoice = create(:payment_invoice, business: business, status: "paid")
      draft_invoice = create(:payment_invoice, business: create(:business, name: "Draft Co"), status: "draft")

      get admin_payment_invoices_path(status: "paid")

      expect(response.body).to include(paid_invoice.business.name)
      expect(response.body).not_to include(draft_invoice.business.name)
    end

    it "redirects employees" do
      sign_out admin
      sign_in create(:user, :employee)

      get admin_payment_invoices_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("do not have access")
    end
  end

  describe "POST /admin/businesses/:business_id/payment_invoices" do
    let(:service_mock) { instance_double(StripePaymentInvoiceService) }

    before do
      allow(StripePaymentInvoiceService).to receive(:new).and_return(service_mock)
      allow(service_mock).to receive(:create_and_send!)
    end

    it "redirects when no manual invoice is available" do
      business.update!(subscription: true, sold_price: 500, subscription_fee: 99, sold_price_paid_at: Time.current)

      post admin_business_payment_invoices_path(business)

      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:alert]).to include("No manual invoice is available")
    end

    it "creates an invoice and redirects" do
      expect {
        post admin_business_payment_invoices_path(business)
      }.to change(PaymentInvoice, :count).by(1)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:notice]).to include("Invoice created and sent")
    end

    it "allows overriding delivery method via params" do
      expect {
        post admin_business_payment_invoices_path(business), params: { payment_invoice: { delivery_method: "sms" } }
      }.to change(PaymentInvoice, :count).by(1)
      expect(PaymentInvoice.last.delivery_method).to eq("sms")
    end

    it "handles generic service errors" do
      allow(service_mock).to receive(:create_and_send!).and_raise(StandardError.new("Generic Error"))
      post admin_business_payment_invoices_path(business)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:alert]).to include("Generic Error")
    end

    it "handles StripePaymentInvoiceService::ConfigurationError" do
      allow(service_mock).to receive(:create_and_send!).and_raise(
        StripePaymentInvoiceService::ConfigurationError.new("STRIPE_SECRET_KEY is not configured")
      )
      post admin_business_payment_invoices_path(business)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:alert]).to include("STRIPE_SECRET_KEY is not configured")
    end

    context "when service fails" do
      before do
        allow(service_mock).to receive(:create_and_send!).and_raise(StandardError, "Stripe Error")
      end

      it "redirects with alert" do
        post admin_business_payment_invoices_path(business)
        expect(response).to redirect_to(admin_business_path(business))
        expect(flash[:alert]).to include("Stripe Error")
      end
    end

    it "redirects if business is invalid for invoice" do
      business.update_columns(email: nil, phone: nil)
      post admin_business_payment_invoices_path(business)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:alert]).to be_present
    end

    it "redirects if user is not an admin" do
      sign_out admin
      sign_in create(:user, :employee)
      post admin_business_payment_invoices_path(business)
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("do not have access")
    end
  end
end
