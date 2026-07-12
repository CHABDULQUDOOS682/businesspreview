# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crm::PaymentEventNotifier do
  let(:business) do
    create(
      :business,
      business_number: "B000005",
      site_api_base_url: "http://dashboard.lvh.me:3001",
      site_api_secret: "shared-secret"
    )
  end

  let(:client) { instance_double(Crm::WebhookClient, configured?: true) }

  before do
    allow(Crm::WebhookClient).to receive(:new).with(business).and_return(client)
  end

  it "sends new_client and payment_received for a first website sale" do
    invoice = create(:payment_invoice, business: business, kind: "one_time", status: "paid")

    expect(client).to receive(:deliver!).with(event: "new_client").ordered
    expect(client).to receive(:deliver!).with(
      event: "payment_received",
      billing_message: "Website sale paid via Stripe",
      billing_level: "success"
    ).ordered

    expect(described_class.new(payment_invoice: invoice).call).to eq(:sent)
  end

  it "skips new_client when a prior website sale was already paid" do
    create(:payment_invoice, business: business, kind: "one_time", status: "paid", stripe_invoice_id: "in_old")
    invoice = create(:payment_invoice, business: business, kind: "one_time", status: "paid", stripe_invoice_id: "in_new")

    expect(client).not_to receive(:deliver!).with(hash_including(event: "new_client"))
    expect(client).not_to receive(:deliver!).with(event: "new_client")
    expect(client).to receive(:deliver!).with(
      event: "payment_received",
      billing_message: "Website sale paid via Stripe",
      billing_level: "success"
    )

    described_class.new(payment_invoice: invoice).call
  end

  it "sends subscription_renewed for subscription payments" do
    invoice = create(:payment_invoice, business: business, kind: "subscription", status: "paid")

    expect(client).to receive(:deliver!).with(
      event: "subscription_renewed",
      billing_message: "Subscription payment received via Stripe",
      billing_level: "success"
    )

    described_class.new(payment_invoice: invoice).call
  end

  it "skips when CRM is not configured" do
    allow(client).to receive(:configured?).and_return(false)
    invoice = create(:payment_invoice, business: business, kind: "subscription", status: "paid")

    expect(client).not_to receive(:deliver!)
    expect(described_class.new(payment_invoice: invoice).call).to eq(:skipped)
  end

  it "skips unknown invoice kinds" do
    invoice = create(:payment_invoice, business: business, kind: "one_time", status: "paid")
    invoice.update_column(:kind, "legacy")

    expect(client).not_to receive(:deliver!)
    expect(described_class.new(payment_invoice: invoice).call).to eq(:skipped)
  end
end
