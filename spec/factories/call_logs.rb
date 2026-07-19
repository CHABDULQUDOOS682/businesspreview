# frozen_string_literal: true

FactoryBot.define do
  factory :call_log do
    association :user
    association :business
    from_number { ENV.fetch("TWILIO_PHONE_NUMBER", "+15005550006") }
    to_number { business&.phone || "+15551234567" }
    direction { "outbound" }
    status { "completed" }
    duration_seconds { 45 }
    sequence(:twilio_call_sid) { |n| "CA#{n.to_s.rjust(32, "0")}" }
  end
end
