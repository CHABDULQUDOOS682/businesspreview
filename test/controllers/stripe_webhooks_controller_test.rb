require "test_helper"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "updates payment invoice when invoice is paid" do
    previous_secret = ENV.delete("STRIPE_WEBHOOK_SECRET")
    business = Business.create!(name: "Paid Co", email: "owner@example.com")
    invoice = business.payment_invoices.create!(
      kind: "one_time",
      amount_cents: 5_000,
      delivery_method: "email",
      stripe_invoice_id: "in_paid",
      status: "open"
    )

    post "/stripe/webhooks",
         params: {
           type: "invoice.paid",
           data: {
             object: {
               id: "in_paid",
               status: "paid",
               hosted_invoice_url: "https://invoice.stripe.com/test",
               invoice_pdf: "https://pay.stripe.com/pdf"
             }
           }
         }.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :ok
    invoice.reload
    assert_equal "paid", invoice.status
    assert_equal "https://invoice.stripe.com/test", invoice.hosted_invoice_url
    assert invoice.paid_at.present?
  ensure
    ENV["STRIPE_WEBHOOK_SECRET"] = previous_secret if previous_secret.present?
  end
end
