# Preview all emails at http://localhost:3000/rails/mailers/payment_invoice_mailer
class PaymentInvoiceMailerPreview < ActionMailer::Preview
  def invoice_link
    business = Business.new(
      name: "Acme Barber Shop",
      owner_name: "John Doe",
      email: "john.doe@example.com"
    )
    payment_invoice = PaymentInvoice.new(
      business: business,
      kind: "subscription",
      amount_cents: 9900,
      currency: "usd",
      payment_token: "test_token"
    )
    PaymentInvoiceMailer.with(payment_invoice: payment_invoice).invoice_link
  end

  def due_soon_followup
    business = Business.new(
      name: "Acme Barber Shop",
      owner_name: "John Doe",
      email: "john.doe@example.com"
    )
    payment_invoice = PaymentInvoice.new(
      business: business,
      kind: "one_time",
      amount_cents: 150000,
      currency: "usd",
      payment_token: "test_token"
    )
    PaymentInvoiceMailer.with(payment_invoice: payment_invoice).due_soon_followup
  end
end
