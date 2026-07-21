FactoryBot.define do
  factory :portfolio_item do
    sequence(:title) { |n| "Local Service Build #{n}" }
    category { "Barbershop" }
    description { "Mobile-ready website with booking and local SEO foundations." }
    metric { "Booking-ready" }
    accent_color { "from-[#213885]/30" }
    sequence(:position) { |n| n }
    active { true }
  end
end
