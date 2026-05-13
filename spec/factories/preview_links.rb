FactoryBot.define do
  factory :preview_link do
    association :business
    template { "barber/barber_modern" }
    sequence(:uuid) { |n| "uuid-#{n}" }
  end
end
