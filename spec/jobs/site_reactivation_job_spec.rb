# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteReactivationJob, type: :job do
  let(:business) do
    create(
      :business,
      subscription: true,
      subscription_fee: 99,
      subscription_payment_status: "suspended",
      site_deactivated_at: 1.day.ago,
      subscription_grace_ends_at: 1.day.from_now,
      site_api_base_url: "https://sites.example.com",
      site_api_secret: "secret"
    )
  end
  let(:payment_invoice) { create(:payment_invoice, business: business, kind: "subscription", status: "paid", paid_at: Time.current) }
  let(:client) { instance_double(SiteLifecycle::Client, reactivate!: true) }

  before do
    allow(SiteLifecycle::Client).to receive(:new).with(business).and_return(client)
  end

  it "reactivates the site and clears suspension fields" do
    described_class.perform_now(business.id, payment_invoice.id)

    expect(client).to have_received(:reactivate!).with(payment_invoice: payment_invoice)
    expect(business.reload).to have_attributes(
      subscription_payment_status: "current",
      site_deactivated_at: nil,
      subscription_grace_ends_at: nil
    )
  end

  it "does nothing when the invoice is unpaid" do
    payment_invoice.update!(status: "invoice_sent", paid_at: nil)

    described_class.perform_now(business.id, payment_invoice.id)

    expect(client).not_to have_received(:reactivate!)
    expect(business.reload.subscription_payment_status).to eq("suspended")
  end

  it "logs configuration errors without changing the business" do
    allow(client).to receive(:reactivate!).and_raise(SiteLifecycle::Client::ConfigurationError, "missing config")
    allow(Rails.logger).to receive(:error)

    described_class.perform_now(business.id, payment_invoice.id)

    expect(business.reload.subscription_payment_status).to eq("suspended")
    expect(Rails.logger).to have_received(:error).with(/missing config/)
  end
end
