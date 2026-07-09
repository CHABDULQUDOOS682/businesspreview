FactoryBot.define do
  factory :google_calendar_channel do
    sequence(:channel_id) { |n| "channel-#{n}" }
    sequence(:resource_id) { |n| "resource-#{n}" }
    expires_at { 2.days.from_now }
  end
end
