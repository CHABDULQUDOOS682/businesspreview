require 'rails_helper'

RSpec.describe "PaymentInvoiceLinks", type: :request do
  let(:business) { create(:business) }
  let(:payment_invoice) { create(:payment_invoice, business: business, hosted_invoice_url: "https://stripe.com/invoice") }

  describe "GET /pay/:token" do
    it "redirects to hosted invoice url and marks as opened" do
      get payment_invoice_link_path(payment_invoice.payment_token)
      expect(response).to redirect_to(payment_invoice.hosted_invoice_url)
      expect(payment_invoice.reload.status).to eq("opened")
    end

    it "renders expired if link is expired" do
      payment_invoice.update(status: "paid")
      get payment_invoice_link_path(payment_invoice.payment_token)
      expect(response).to have_http_status(:gone)
      expect(response).to render_template(:expired)
    end

    it "renders expired if hosted_invoice_url is blank" do
      payment_invoice.update(hosted_invoice_url: nil)
      get payment_invoice_link_path(payment_invoice.payment_token)
      expect(response).to have_http_status(:gone)
    end
  end
end
