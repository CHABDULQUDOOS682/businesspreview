FactoryBot.define do
  factory :message do
    association :business
    from_number { "+1234567890" }
    to_number { "+0987654321" }
    body { "Hello this is a message" }
    direction { "inbound" }
  end
end
