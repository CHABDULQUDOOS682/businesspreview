FactoryBot.define do
  factory :developer_task do
    id { "task-123" }
    title { "Fix CSS Bug" }
    description { "The button is not aligned properly." }
    status { "pending" }
    source_key { "source-1" }
    source_name { "GitHub" }
    priority { "high" }
    business_name { "Acme Corp" }
    assignee { "John Doe" }
    external_url { "https://github.com/issues/123" }
    created_at { Time.current }
    updated_at { Time.current }

    initialize_with { new(attributes) }
    skip_create
  end
end
