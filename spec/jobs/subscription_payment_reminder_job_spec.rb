# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubscriptionPaymentReminderJob, type: :job do
  include ActiveJob::TestHelper

  let(:business) { create(:business, subscription: true, subscription_fee: 99, email: "client@example.com") }
  let!(:payment_invoice) do
    create(
      :payment_invoice,
      business: business,
      kind: "subscription",
      status: "invoice_sent",
      sent_at: 10.days.ago,
      reminder_count: 0
    )
  end
  let(:lifecycle_service) { instance_double(Billing::InvoiceLifecycleService, handle_unpaid_state!: true) }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(Billing::InvoiceLifecycleService).to receive(:new).and_return(lifecycle_service)
    allow(PaymentInvoiceMailer).to receive_message_chain(:with, :subscription_overdue_reminder, :deliver_later)
  end

  it "sends overdue reminders and updates reminder state" do
    described_class.perform_now

    expect(PaymentInvoiceMailer).to have_received(:with).with(
      payment_invoice: payment_invoice,
      reminder_number: 1
    )
    expect(payment_invoice.reload.reminder_count).to eq(1)
    expect(lifecycle_service).to have_received(:handle_unpaid_state!).with(status: "invoice_sent")
  end

  it "skips paid invoices" do
    payment_invoice.update!(status: "paid")

    described_class.perform_now

    expect(PaymentInvoiceMailer).not_to have_received(:with)
  end

  it "skips invoices without a business email" do
    business.update!(email: nil)

    described_class.perform_now

    expect(PaymentInvoiceMailer).not_to have_received(:with)
  end
end
