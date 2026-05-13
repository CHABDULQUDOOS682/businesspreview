FactoryBot.define do
  factory :note do
    association :business
    body { "This is an important note." }
  end
end
