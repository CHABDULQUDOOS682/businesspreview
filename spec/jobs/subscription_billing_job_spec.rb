# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubscriptionBillingJob, type: :job do
  let(:business) do
    create(
      :business,
      subscription: true,
      sold_price: 500,
      subscription_fee: 99,
      sold_price_paid_at: 60.days.ago,
      next_subscription_invoice_at: 1.day.ago,
      subscription_payment_status: "current",
      email: "billing@example.com"
    )
  end

  before do
    allow(Billing::SubscriptionBillingService).to receive(:new).and_return(
      instance_double(Billing::SubscriptionBillingService, create_and_send!: true)
    )
  end

  it "processes businesses due for subscription billing" do
    business

    expect(Billing::SubscriptionBillingService).to receive(:new).with(business).and_return(
      instance_double(Billing::SubscriptionBillingService, create_and_send!: true)
    )

    described_class.perform_now
  end

  it "logs and continues when billing fails for a business" do
    business
    failing_service = instance_double(Billing::SubscriptionBillingService)
    allow(Billing::SubscriptionBillingService).to receive(:new).and_return(failing_service)
    allow(failing_service).to receive(:create_and_send!).and_raise(StandardError, "stripe down")
    allow(Rails.logger).to receive(:error)

    expect { described_class.perform_now }.not_to raise_error
    expect(Rails.logger).to have_received(:error).with(/stripe down/)
  end
end
