FactoryBot.define do
  factory :commission do
    association :business
    association :user
    association :payment_invoice
    kind { "one_time" }
    month_number { nil }
    base_amount { 100.0 }
    percentage { 10.0 }
    status { "pending" }
  end
end
