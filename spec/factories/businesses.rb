FactoryBot.define do
  factory :business do
    name { "Acme Corp" }
    owner_name { "John Doe" }
    city { "New York" }
    country { "USA" }
    business_location { "https://www.google.com/maps/place/Acme+Corp" }
    sequence(:email) { |n| "contact#{n}@acmecorp.com" }
    sequence(:phone) { |n| "+123456789#{n}" }
    sequence(:business_number) { |n| format("B%06d", n) }
    visit_count { 0 }
    subscription { false }
    sold_price { 500 }
    subscription_fee { 50 }
  end
end
