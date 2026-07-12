# frozen_string_literal: true

module Crm
  class PaymentEventNotifier
    def initialize(payment_invoice:)
      @payment_invoice = payment_invoice
      @business = payment_invoice.business
      @client = WebhookClient.new(@business)
    end

    def call
      unless @client.configured?
        Rails.logger.info(
          "[Crm::PaymentEventNotifier] skipped business ##{@business.id} — " \
          "site_api_base_url, site_api_secret, and business_number are required"
        )
        return :skipped
      end

      case @payment_invoice.kind
      when "one_time"
        notify_one_time_paid!
      when "subscription"
        notify_subscription_paid!
      else
        :skipped
      end
    end

    private

    def notify_one_time_paid!
      @client.deliver!(event: "new_client") if first_website_payment?

      @client.deliver!(
        event: "payment_received",
        billing_message: "Website sale paid via Stripe",
        billing_level: "success"
      )
      :sent
    end

    def notify_subscription_paid!
      @client.deliver!(
        event: "subscription_renewed",
        billing_message: "Subscription payment received via Stripe",
        billing_level: "success"
      )
      :sent
    end

    def first_website_payment?
      !PaymentInvoice
        .where(business_id: @business.id, kind: "one_time", status: "paid")
        .where.not(id: @payment_invoice.id)
        .exists?
    end
  end
end
