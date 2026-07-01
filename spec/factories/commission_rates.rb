FactoryBot.define do
  factory :commission_rate do
    kind { "one_time" }
    month_number { nil }
    percentage { 10.0 }

    trait :subscription do
      kind { "subscription" }
      month_number { 1 }
      percentage { 8.0 }
    end
  end
end
