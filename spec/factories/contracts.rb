# frozen_string_literal: true

FactoryBot.define do
  factory :contract do
    association :business
    association :created_by, factory: [ :user, :admin ]
    kind { "subscription" }
    status { "draft" }
    package_key { "growth" }
    title { "Growth partnership agreement" }
    client_name { business.name }
    client_email { business.email.presence || "client@example.com" }
    agency_name { "DevDeBizz" }
    scope_of_work { "Hosting and updates" }
    pricing_terms { "One-time setup and monthly fee" }
    timeline_terms { "Monthly renewal" }
    termination_terms { "30 days notice" }
    amount_cents { 5000 }
    currency { "usd" }

    trait :sent do
      status { "sent" }
      sent_at { Time.current }
    end

    trait :signed do
      status { "signed" }
      sent_at { 1.day.ago }
      client_signer_name { "Jane Client" }
      client_signed_at { Time.current }
      client_signer_ip { "127.0.0.1" }
      client_signer_user_agent { "RSpec" }
      agency_signer_name { "DevDeBizz" }
      agency_signed_at { Time.current }
    end

    trait :project do
      kind { "one_time_project" }
      package_key { "starter" }
      title { "Starter website project agreement" }
      amount_cents { 19900 }
    end
  end
end
