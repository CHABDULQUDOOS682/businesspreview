FactoryBot.define do
  factory :employee_commission_rate do
    association :user
    kind { "one_time" }
    month_number { nil }
    percentage { 12.0 }

    trait :subscription do
      kind { "subscription" }
      month_number { 1 }
      percentage { 9.0 }
    end
  end
end
