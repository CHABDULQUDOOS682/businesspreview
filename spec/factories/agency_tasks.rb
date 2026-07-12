# frozen_string_literal: true

FactoryBot.define do
  factory :agency_task do
    business
    source { "content_update" }
    sequence(:external_id) { |n| n.to_s }
    business_number { business.business_number }
    title { "Update homepage headline" }
    description { "Please change the hero text on the homepage." }
    status { "pending" }
    external_url { "https://admin.example.com/admin/content-updates/1" }
    requester_name { "Jane Owner" }
    requester_email { "owner@example.com" }
    requested_at { Time.current }
    raw_payload { {} }
  end
end
