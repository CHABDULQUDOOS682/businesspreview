FactoryBot.define do
  factory :payment_invoice do
    association :business
    kind { "one_time" }
    amount_cents { 50000 } # $500.00
    currency { "usd" }
    status { "draft" }
    delivery_method { "email" }
    billing_interval { "month" }
    days_until_due { 7 }
    sequence(:payment_token) { |n| "token_#{n}" }
  end
end
