# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteDeactivationJob, type: :job do
  let(:business) do
    create(
      :business,
      subscription: true,
      subscription_fee: 99,
      subscription_payment_status: "past_due",
      site_api_base_url: "https://sites.example.com",
      site_api_secret: "secret"
    )
  end
  let(:payment_invoice) { create(:payment_invoice, business: business, kind: "subscription", status: "invoice_sent") }
  let(:client) { instance_double(SiteLifecycle::Client, deactivate!: true) }

  before do
    allow(SiteLifecycle::Client).to receive(:new).with(business).and_return(client)
  end

  it "deactivates the site and suspends the business" do
    described_class.perform_now(business.id, payment_invoice.id)

    expect(client).to have_received(:deactivate!).with(payment_invoice: payment_invoice)
    expect(business.reload).to have_attributes(
      subscription_payment_status: "suspended",
      site_deactivated_at: be_present
    )
  end

  it "does nothing when the invoice is already paid" do
    payment_invoice.update!(status: "paid")

    described_class.perform_now(business.id, payment_invoice.id)

    expect(client).not_to have_received(:deactivate!)
    expect(business.reload.subscription_payment_status).to eq("past_due")
  end

  it "does nothing when the business is already suspended" do
    business.update!(subscription_payment_status: "suspended")

    described_class.perform_now(business.id, payment_invoice.id)

    expect(client).not_to have_received(:deactivate!)
  end

  it "keeps the business past due when site api configuration is missing" do
    allow(client).to receive(:deactivate!).and_raise(SiteLifecycle::Client::ConfigurationError, "missing config")
    allow(Rails.logger).to receive(:error)

    described_class.perform_now(business.id, payment_invoice.id)

    expect(business.reload.subscription_payment_status).to eq("past_due")
    expect(Rails.logger).to have_received(:error).with(/missing config/)
  end
end
