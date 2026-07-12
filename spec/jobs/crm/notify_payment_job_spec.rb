# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crm::NotifyPaymentJob, type: :job do
  let(:business) do
    create(
      :business,
      business_number: "B000099",
      site_api_base_url: "https://dashboard.example.com",
      site_api_secret: "secret"
    )
  end
  let(:payment_invoice) { create(:payment_invoice, business: business, kind: "subscription", status: "paid") }

  it "notifies SitePilot that payment was received" do
    notifier = instance_double(Crm::PaymentEventNotifier, call: :sent)
    allow(Crm::PaymentEventNotifier).to receive(:new)
      .with(payment_invoice: payment_invoice)
      .and_return(notifier)

    described_class.perform_now(payment_invoice.id)

    expect(notifier).to have_received(:call)
  end
end
