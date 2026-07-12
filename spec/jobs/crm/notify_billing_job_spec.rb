# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crm::NotifyBillingJob, type: :job do
  include ActiveJob::TestHelper

  let(:business) do
    create(
      :business,
      business_number: "B000099",
      site_api_base_url: "https://dashboard.example.com",
      site_api_secret: "secret"
    )
  end
  let(:payment_invoice) { create(:payment_invoice, business: business, kind: "subscription") }

  it "notifies SitePilot for the billing event" do
    notifier = instance_double(Crm::BillingEventNotifier, call: :sent)
    allow(Crm::BillingEventNotifier).to receive(:new)
      .with(payment_invoice: payment_invoice)
      .and_return(notifier)

    described_class.perform_now(payment_invoice.id, "invoice_sent")

    expect(notifier).to have_received(:call).with("invoice_sent")
  end
end
