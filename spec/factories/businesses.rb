FactoryBot.define do
  factory :business do
    name { "Acme Corp" }
    owner_name { "John Doe" }
    city { "New York" }
    country { "USA" }
    sequence(:email) { |n| "contact#{n}@acmecorp.com" }
    sequence(:phone) { |n| "+123456789#{n}" }
    visit_count { 0 }
    subscription { false }
    sold_price { 500 }
    subscription_fee { 50 }
  end
end
