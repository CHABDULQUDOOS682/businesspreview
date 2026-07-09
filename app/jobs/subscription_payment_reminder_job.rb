class SubscriptionPaymentReminderJob < ApplicationJob
  queue_as :default

  REMINDER_SCHEDULE = [
    { days_after_due: 1 },
    { days_after_due: 4 }
  ].freeze

  def perform
    PaymentInvoice.subscription_fee_reminder_candidates.find_each do |payment_invoice|
      send_due_reminders!(payment_invoice)
      Billing::InvoiceLifecycleService.new(payment_invoice).handle_unpaid_state!(status: payment_invoice.status)
    end
  end

  private

  def send_due_reminders!(payment_invoice)
    return if payment_invoice.paid?
    return if payment_invoice.business.email.blank?
    return if payment_invoice.sent_at.blank?

    due_at = payment_invoice.sent_at + PaymentInvoice::DEFAULT_DAYS_UNTIL_DUE.days
    return if Time.current < due_at

    REMINDER_SCHEDULE.each_with_index do |schedule, index|
      reminder_number = index + 1
      next if payment_invoice.reminder_count >= reminder_number
      next if Time.current < due_at + schedule[:days_after_due].days

      PaymentInvoiceMailer.with(payment_invoice: payment_invoice, reminder_number: reminder_number)
                          .subscription_overdue_reminder
                          .deliver_later

      payment_invoice.update!(
        reminder_count: reminder_number,
        last_reminder_sent_at: Time.current
      )
    end
  end
end
