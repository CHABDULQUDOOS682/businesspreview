FactoryBot.define do
  factory :preview_link do
    association :business
    template { "barber/barber_modern" }
    # Left unset so the model's own token generation is what gets exercised.
  end
end
