require "test_helper"

class Admin::PaymentInvoicesControllerTest < ActionDispatch::IntegrationTest
  test "admin can create and send a payment invoice" do
    user = User.create!(email: "admin@example.com", password: "password123", role: "admin")
    business = Business.create!(name: "Client Co", email: "owner@example.com", sold_price: 1200)
    fake_service = Object.new
    fake_service.define_singleton_method(:create_and_send!) { true }

    sign_in user

    StripePaymentInvoiceService.stub(:new, fake_service) do
      assert_difference -> { PaymentInvoice.count }, 1 do
        post admin_business_payment_invoices_path(business), params: {
          payment_invoice: {
            kind: "one_time",
            amount: "1200.00",
            currency: "USD",
            delivery_method: "email",
            days_until_due: 30,
            billing_interval: "month"
          }
        }
      end
    end

    invoice = PaymentInvoice.last
    assert_redirected_to admin_business_path(business)
    assert_equal 120_000, invoice.amount_cents
    assert_equal "usd", invoice.currency
  end

  test "employee cannot create payment invoices" do
    user = User.create!(email: "employee@example.com", password: "password123", role: "employee")
    business = Business.create!(name: "Client Co", email: "owner@example.com", sold_price: 1200)

    sign_in user

    assert_no_difference -> { PaymentInvoice.count } do
      post admin_business_payment_invoices_path(business), params: {
        payment_invoice: {
          kind: "one_time",
          amount: "1200.00",
          currency: "USD",
          delivery_method: "email",
          days_until_due: 30,
          billing_interval: "month"
        }
      }
    end

    assert_redirected_to admin_root_path
  end
end
