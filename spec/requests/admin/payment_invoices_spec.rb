require 'rails_helper'

RSpec.describe "Admin::PaymentInvoices", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business) }

  before do
    sign_in admin
  end

  describe "POST /admin/businesses/:business_id/payment_invoices" do
    let(:service_mock) { instance_double(StripePaymentInvoiceService) }

    before do
      allow(StripePaymentInvoiceService).to receive(:new).and_return(service_mock)
      allow(service_mock).to receive(:create_and_send!)
    end

    it "creates an invoice and redirects" do
      expect {
        post admin_business_payment_invoices_path(business)
      }.to change(PaymentInvoice, :count).by(1)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:notice]).to eq("Invoice created and sent.")
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
