# frozen_string_literal: true

module Crm
  class BillingEventNotifier
    EVENTS = %w[invoice_sent payment_overdue site_suspended].freeze

    def initialize(payment_invoice:)
      @payment_invoice = payment_invoice
      @business = payment_invoice.business
      @client = WebhookClient.new(@business)
    end

    def call(event)
      event = event.to_s
      raise ArgumentError, "Unsupported billing event: #{event}" unless EVENTS.include?(event)

      unless @client.configured?
        Rails.logger.info(
          "[Crm::BillingEventNotifier] skipped business ##{@business.id} — CRM not configured"
        )
        return :skipped
      end

      return :skipped unless @payment_invoice.kind == "subscription"

      case event
      when "invoice_sent" then notify_invoice_sent!
      when "payment_overdue" then notify_payment_overdue!
      when "site_suspended" then notify_site_suspended!
      end
    end

    private

    def notify_invoice_sent!
      due = @payment_invoice.due_at
      @client.deliver!(
        event: "invoice_sent",
        billing_message: "Your subscription invoice is ready. Please pay#{due ? " by #{due.to_date.to_fs(:long)}" : ""}.",
        billing_level: "info",
        invoice_url: invoice_url,
        due_at: due&.iso8601,
        amount_cents: @payment_invoice.amount_cents,
        currency: @payment_invoice.currency,
        lock_dashboard: false
      )
      :sent
    end

    def notify_payment_overdue!
      grace_ends = @business.subscription_grace_ends_at
      @client.deliver!(
        event: "payment_overdue",
        billing_message: overdue_message(grace_ends),
        billing_level: "warning",
        invoice_url: invoice_url,
        due_at: @payment_invoice.due_at&.iso8601,
        grace_ends_at: grace_ends&.iso8601,
        amount_cents: @payment_invoice.amount_cents,
        currency: @payment_invoice.currency,
        lock_dashboard: false
      )
      :sent
    end

    def notify_site_suspended!
      @client.deliver!(
        event: "site_suspended",
        billing_message: "Your public website is paused because the subscription fee was not paid. Pay the invoice to restore your site and dashboard.",
        billing_level: "warning",
        invoice_url: invoice_url,
        due_at: @payment_invoice.due_at&.iso8601,
        grace_ends_at: @business.subscription_grace_ends_at&.iso8601,
        amount_cents: @payment_invoice.amount_cents,
        currency: @payment_invoice.currency,
        lock_dashboard: true
      )
      :sent
    end

    def overdue_message(grace_ends)
      if grace_ends.present?
        "Payment is overdue. Your website will be turned off on #{grace_ends.to_date.to_fs(:long)} if this invoice is not paid."
      else
        "Payment is overdue. Please pay your subscription invoice to avoid your website being turned off."
      end
    end

    def invoice_url
      # Prefer the CRM /pay/:token redirect so opens are tracked; Stripe must have hosted_invoice_url set.
      url_options = Rails.application.config.action_mailer.default_url_options.compact
      Rails.application.routes.url_helpers.payment_invoice_link_url(
        @payment_invoice.payment_token,
        **url_options
      )
    end
  end
end
