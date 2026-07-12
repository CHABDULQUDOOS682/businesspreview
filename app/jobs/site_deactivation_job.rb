class SiteDeactivationJob < ApplicationJob
  queue_as :default

  def perform(business_id, payment_invoice_id)
    business = Business.find(business_id)
    payment_invoice = PaymentInvoice.find(payment_invoice_id)

    return if payment_invoice.paid?
    return if business.subscription_payment_status == "suspended"

    SiteLifecycle::Client.new(business).deactivate!(payment_invoice: payment_invoice)

    business.update!(
      subscription_payment_status: "suspended",
      site_deactivated_at: Time.current
    )

    Crm::NotifyBillingJob.perform_later(payment_invoice.id, "site_suspended")
  rescue SiteLifecycle::Client::ConfigurationError => e
    Rails.logger.error("[SiteDeactivationJob] business ##{business_id}: #{e.message}")
    business.update!(subscription_payment_status: "past_due") if business.subscription_payment_status != "suspended"
  end
end
