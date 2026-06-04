require "rails_helper"

RSpec.describe PaymentInvoiceFollowupJob, type: :job do
  include ActiveJob::TestHelper

  let(:business) { create(:business, email: "client@example.com") }
  let(:payment_invoice) { create(:payment_invoice, business: business, status: "invoice_sent", delivery_method: "email") }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "#perform" do
    it "delivers the followup email if not paid and no followup sent" do
      expect {
        perform_enqueued_jobs do
          PaymentInvoiceFollowupJob.perform_now(payment_invoice)
        end
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(payment_invoice.reload.followup_sent_at).to be_present
    end

    it "does not deliver if already paid" do
      payment_invoice.update(status: "paid")
      expect {
        perform_enqueued_jobs do
          PaymentInvoiceFollowupJob.perform_now(payment_invoice)
        end
      }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "does not deliver if followup already sent" do
      payment_invoice.update(followup_sent_at: Time.current)
      expect {
        perform_enqueued_jobs do
          PaymentInvoiceFollowupJob.perform_now(payment_invoice)
        end
      }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "does not deliver if business has no email" do
      payment_invoice.update_columns(delivery_method: "sms")
      business.update_columns(email: nil)
      expect {
        perform_enqueued_jobs do
          PaymentInvoiceFollowupJob.perform_now(payment_invoice)
        end
      }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end
end
