FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { "employee" }
    active { true }

    trait :admin do
      role { "admin" }
    end

    trait :super_admin do
      role { "super_admin" }
    end
  end
end
