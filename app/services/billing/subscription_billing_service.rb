module Billing
  class SubscriptionBillingService
    BILLING_CYCLE = InvoiceLifecycleService::BILLING_CYCLE

    def initialize(business)
      @business = business
    end

    def create_and_send!
      raise ArgumentError, "Business is not due for subscription billing" unless @business.due_for_subscription_billing?

      period_start = @business.next_subscription_invoice_at.to_date
      period_end = period_start + BILLING_CYCLE

      payment_invoice = @business.payment_invoices.create!(
        kind: "subscription",
        amount_cents: PaymentInvoice.dollars_to_cents(@business.subscription_fee),
        currency: "usd",
        delivery_method: PaymentInvoice.default_delivery_method_for(@business),
        days_until_due: PaymentInvoice::DEFAULT_DAYS_UNTIL_DUE,
        billing_interval: PaymentInvoice::DEFAULT_BILLING_INTERVAL,
        billing_period_start: period_start,
        billing_period_end: period_end
      )

      StripePaymentInvoiceService.new(payment_invoice).create_and_send!

      @business.update!(
        next_subscription_invoice_at: @business.next_subscription_invoice_at + BILLING_CYCLE,
        subscription_payment_status: "current"
      )

      payment_invoice
    end
  end
end
