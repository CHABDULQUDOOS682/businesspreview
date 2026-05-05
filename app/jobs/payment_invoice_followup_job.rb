class PaymentInvoiceFollowupJob < ApplicationJob
  queue_as :default

  def perform(payment_invoice)
    return if payment_invoice.paid?
    return if payment_invoice.followup_sent_at.present?
    return if payment_invoice.business.email.blank?

    PaymentInvoiceMailer.with(payment_invoice: payment_invoice).due_soon_followup.deliver_now
    payment_invoice.update!(followup_sent_at: Time.current)
  end
end
