# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crm::BillingEventNotifier do
  let(:business) do
    create(
      :business,
      business_number: "B000099",
      site_api_base_url: "https://dashboard.example.com",
      site_api_secret: "secret",
      subscription_grace_ends_at: 3.days.from_now
    )
  end
  let(:payment_invoice) do
    create(
      :payment_invoice,
      business: business,
      kind: "subscription",
      amount_cents: 9900,
      currency: "usd",
      sent_at: Time.current,
      payment_token: "pay_token_123"
    )
  end
  let(:client) { instance_double(Crm::WebhookClient, configured?: true) }

  before do
    allow(Crm::WebhookClient).to receive(:new).with(business).and_return(client)
    allow(client).to receive(:deliver!)
    allow(Rails.application.routes.url_helpers).to receive(:payment_invoice_link_url)
      .and_return("https://crm.example.com/pay/pay_token_123")
  end

  it "skips one-time invoices" do
    payment_invoice.update!(kind: "one_time")

    expect(described_class.new(payment_invoice: payment_invoice).call("invoice_sent")).to eq(:skipped)
    expect(client).not_to have_received(:deliver!)
  end

  it "notifies invoice_sent with invoice link" do
    expect(described_class.new(payment_invoice: payment_invoice).call("invoice_sent")).to eq(:sent)

    expect(client).to have_received(:deliver!).with(
      hash_including(
        event: "invoice_sent",
        invoice_url: "https://crm.example.com/pay/pay_token_123",
        amount_cents: 9900,
        lock_dashboard: false
      )
    )
  end

  it "notifies payment_overdue with grace end" do
    described_class.new(payment_invoice: payment_invoice).call("payment_overdue")

    expect(client).to have_received(:deliver!).with(
      hash_including(
        event: "payment_overdue",
        billing_level: "warning",
        grace_ends_at: business.subscription_grace_ends_at.iso8601,
        lock_dashboard: false
      )
    )
  end

  it "notifies site_suspended with dashboard lock" do
    described_class.new(payment_invoice: payment_invoice).call("site_suspended")

    expect(client).to have_received(:deliver!).with(
      hash_including(
        event: "site_suspended",
        lock_dashboard: true,
        invoice_url: "https://crm.example.com/pay/pay_token_123"
      )
    )
  end
end
