require "test_helper"

class PaymentInvoiceTest < ActiveSupport::TestCase
  test "defaults one time amount from business sold price" do
    business = Business.new(sold_price: 499.99)

    assert_equal 49_999, PaymentInvoice.default_amount_for(business, "one_time")
  end

  test "defaults subscription amount from business subscription fee" do
    business = Business.new(subscription_fee: 79.50)

    assert_equal 7_950, PaymentInvoice.default_amount_for(business, "subscription")
  end

  test "email delivery requires business email" do
    business = Business.create!(name: "No Email Co", phone: "+15555550101")
    invoice = business.payment_invoices.new(
      kind: "one_time",
      amount_cents: 10_000,
      delivery_method: "email"
    )

    assert_not invoice.valid?
    assert_includes invoice.errors[:delivery_method], "requires a business email"
  end

  test "sms delivery requires business phone" do
    business = Business.create!(name: "No Phone Co", email: "owner@example.com")
    invoice = business.payment_invoices.new(
      kind: "one_time",
      amount_cents: 10_000,
      delivery_method: "sms"
    )

    assert_not invoice.valid?
    assert_includes invoice.errors[:delivery_method], "requires a business phone number"
  end
end
