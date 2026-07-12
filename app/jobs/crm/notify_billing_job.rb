# frozen_string_literal: true

module Crm
  class NotifyBillingJob < ApplicationJob
    queue_as :default

    discard_on ActiveRecord::RecordNotFound
    discard_on Crm::WebhookClient::ConfigurationError

    retry_on Crm::WebhookClient::Error, wait: :polynomially_longer, attempts: 5

    def perform(payment_invoice_id, event)
      payment_invoice = PaymentInvoice.find(payment_invoice_id)
      Crm::BillingEventNotifier.new(payment_invoice: payment_invoice).call(event)
    end
  end
end
