FactoryBot.define do
  factory :business_import do
    association :imported_by, factory: :user
    filename { "businesses.csv" }
    completed_at { Time.current }
  end
end
