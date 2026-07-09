FactoryBot.define do
  factory :meeting do
    association :user, factory: [ :user, :employee ]
    association :business
    client_name { "Jane Client" }
    sequence(:client_email) { |n| "client#{n}@example.com" }
    client_phone { "+1234567890" }
    title { "Discovery call" }
    description { "Initial meeting" }
    starts_at { 2.days.from_now.change(hour: 10, min: 0) }
    duration_minutes { 30 }
    status { "scheduled" }
    google_event_id { nil }
    google_meet_url { nil }
  end
end
