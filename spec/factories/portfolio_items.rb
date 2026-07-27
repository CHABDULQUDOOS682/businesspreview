FactoryBot.define do
  factory :portfolio_item do
    sequence(:title) { |n| "Barbershop Website Redesign #{n}" }
    category { "Barbershop" }
    description { "Mobile-ready website with booking and SEO foundations for service businesses." }
    metric { "+ Booking requests" }
    accent_color { "from-[#213885]/30" }
    sequence(:position) { |n| n }
    active { true }
  end
end
