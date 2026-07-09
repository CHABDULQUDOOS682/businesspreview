module Billing
  class InvoiceLifecycleService
    BILLING_CYCLE = 30.days
    GRACE_PERIOD = 7.days

    def initialize(payment_invoice)
      @payment_invoice = payment_invoice
      @business = payment_invoice.business
    end

    def handle_paid!(paid_at: Time.current)
      sync_business_invoice_snapshot!(paid_at: paid_at, status: "paid")

      case @payment_invoice.kind
      when "one_time"
        handle_one_time_paid!(paid_at)
      when "subscription"
        handle_subscription_fee_paid!(paid_at)
      end
    end

    def handle_unpaid_state!(status:)
      sync_business_invoice_snapshot!(status: status)

      return unless subscription_fee_invoice?
      return if @payment_invoice.paid?

      mark_past_due! if overdue?
      enqueue_site_deactivation_if_grace_expired!
    end

    private

    def subscription_fee_invoice?
      @payment_invoice.kind == "subscription"
    end

    def handle_one_time_paid!(paid_at)
      attrs = { sold_at: paid_at }
      attrs[:sold_price_paid_at] = paid_at if @business.sold_price.present?

      if @business.subscription_active? && @business.subscription_fee.present?
        attrs[:subscription_billing_anchor_at] = paid_at
        attrs[:next_subscription_invoice_at] = paid_at + BILLING_CYCLE
        attrs[:subscription_payment_status] = "current"
      end

      @business.update!(attrs)
    end

    def handle_subscription_fee_paid!(paid_at)
      @business.update!(
        subscription_payment_status: "current",
        subscription_grace_ends_at: nil,
        last_invoice_paid_at: paid_at,
        last_payment_failed_at: nil
      )

      if @business.site_deactivated_at.present?
        SiteReactivationJob.perform_later(@business.id, @payment_invoice.id)
      end
    end

    def mark_past_due!
      grace_ends_at = due_at + GRACE_PERIOD
      return if @business.subscription_payment_status == "suspended"

      @business.update!(
        subscription_payment_status: "past_due",
        subscription_grace_ends_at: grace_ends_at,
        last_payment_failed_at: Time.current
      )
    end

    def overdue?
      return false if @payment_invoice.sent_at.blank?

      Time.current > due_at
    end

    def due_at
      @payment_invoice.sent_at + PaymentInvoice::DEFAULT_DAYS_UNTIL_DUE.days
    end

    def enqueue_site_deactivation_if_grace_expired!
      return unless @business.subscription_grace_ends_at.present?
      return if Time.current < @business.subscription_grace_ends_at
      return if @business.subscription_payment_status == "suspended"

      SiteDeactivationJob.perform_later(@business.id, @payment_invoice.id)
    end

    def sync_business_invoice_snapshot!(paid_at: nil, status:)
      attrs = {
        last_invoice_id: @payment_invoice.stripe_invoice_id,
        last_invoice_status: status
      }
      attrs[:last_invoice_paid_at] = paid_at if paid_at.present?

      @business.update!(attrs)
    end
  end
end
