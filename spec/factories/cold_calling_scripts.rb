FactoryBot.define do
  factory :cold_calling_script do
    association :created_by, factory: [ :user, :admin ]
    sequence(:title) { |n| "Cold call script #{n}" }
    body { "Hi, this is a sample cold calling script for the team." }
    category { "Opening" }
    active { true }
  end
end
