FactoryBot.define do
  factory :business_commission_rate do
    association :business
    kind { "one_time" }
    month_number { nil }
    percentage { 15.0 }

    trait :subscription do
      kind { "subscription" }
      month_number { 1 }
      percentage { 10.0 }
    end
  end
end
