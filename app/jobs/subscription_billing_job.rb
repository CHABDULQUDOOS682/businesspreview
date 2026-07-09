class SubscriptionBillingJob < ApplicationJob
  queue_as :default

  def perform
    Business.subscription_billing_due.find_each do |business|
      Billing::SubscriptionBillingService.new(business).create_and_send!
    rescue StandardError => e
      Rails.logger.error("[SubscriptionBillingJob] business ##{business.id}: #{e.message}")
    end
  end
end
