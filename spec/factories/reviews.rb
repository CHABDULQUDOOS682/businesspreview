FactoryBot.define do
  factory :review do
    association :business
    client_name { "Jane Doe" }
    client_role { "CEO, Acme Inc" }
    content { "Working with this team was a game changer for our business." }
    rating { 5 }
    active { false }
  end
end
