require 'rails_helper'

RSpec.describe "PaymentInvoiceLinks", type: :request do
  let(:business) { create(:business) }

  let(:payment_invoice) do
    create(
      :payment_invoice,
      business: business,
      hosted_invoice_url: "https://invoice.stripe.com/inv_123",
      status: "draft"
    )
  end

  describe "GET /pay/:token" do
    it "redirects to hosted invoice url and marks as opened" do
      get payment_invoice_link_path(payment_invoice.payment_token)

      payment_invoice.reload

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to("https://invoice.stripe.com/inv_123")
      expect(payment_invoice.status).to eq("opened")
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
