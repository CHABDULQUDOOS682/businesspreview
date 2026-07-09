class SiteReactivationJob < ApplicationJob
  queue_as :default

  def perform(business_id, payment_invoice_id)
    business = Business.find(business_id)
    payment_invoice = PaymentInvoice.find(payment_invoice_id)

    return unless payment_invoice.paid?

    SiteLifecycle::Client.new(business).reactivate!(payment_invoice: payment_invoice)

    business.update!(
      subscription_payment_status: "current",
      site_deactivated_at: nil,
      subscription_grace_ends_at: nil
    )
  rescue SiteLifecycle::Client::ConfigurationError => e
    Rails.logger.error("[SiteReactivationJob] business ##{business_id}: #{e.message}")
  end
end
