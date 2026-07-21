FactoryBot.define do
  factory :blog_post do
    sequence(:title) { |n| "Service business insight #{n}" }
    sequence(:slug) { |n| "service-business-insight-#{n}" }
    category { "Design" }
    excerpt { "Practical guidance for local service websites and follow-up systems." }
    read_time_label { "5 min read" }
    published_on { Date.current }
    active { true }
  end
end
