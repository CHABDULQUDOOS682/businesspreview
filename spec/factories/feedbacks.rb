FactoryBot.define do
  factory :feedback do
    association :user, factory: [ :user, :employee ]
    title { "Dashboard loading slowly" }
    description { "The businesses page takes several seconds to load on first visit." }
    feedback_type { "performance" }
    priority { "medium" }
    status { "pending" }
    browser { "Mozilla/5.0" }
    operating_system { "MacIntel" }
    page_url { "https://example.com/admin/businesses" }

    trait :bug do
      feedback_type { "bug" }
      steps_to_reproduce { "1. Open dashboard\n2. Click Businesses" }
      expected_result { "Page loads within 2 seconds" }
      actual_result { "Page hangs for 10 seconds" }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
      resolved_at { Time.current }
    end
  end
end
