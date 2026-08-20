unless User.exists?(role: 2)
  User.create!(
    email: "super_admin@example.com",
    password: "Password@123",
    password_confirmation: "Password@123",
    role: 2
  )
end

unless User.exists?(email: "admin@example.com")
  User.create!(
    email: "admin@example.com",
    password: "Password@123",
    password_confirmation: "Password@123",
    role: 1
  )
end

unless User.exists?(email: "employee@example.com")
  User.create!(
    email: "employee@example.com",
    password: "Password@123",
    password_confirmation: "Password@123",
    role: 0
  )
end

[
  { kind: "one_time", month_number: nil, percentage: 10.0 },
  { kind: "subscription", month_number: 1, percentage: 8.0 },
  { kind: "subscription", month_number: 2, percentage: 4.0 },
  { kind: "subscription", month_number: 3, percentage: 2.0 }
].each do |attrs|
  CommissionRate.find_or_create_by!(kind: attrs[:kind], month_number: attrs[:month_number]) do |r|
    r.percentage = attrs[:percentage]
  end
end

# Demo nurture businesses for local pagination only — never seed into test/CI/prod.
if Rails.env.development?
  niches = [ "Salon", "Barbershop", "Dental", "HVAC", "Plumbing", "Landscaping", "Auto Repair", "Cafe" ]
  cities = [ "Austin", "Denver", "Seattle", "Chicago", "Miami", "Phoenix", "Portland", "Atlanta" ]

  25.times do |i|
    n = i + 1
    phone = format("+1555%07d", n)
    next if Business.exists?(phone: phone)

    Business.create!(
      name: "Demo Business #{n}",
      owner_name: "Owner #{n}",
      city: cities[i % cities.length],
      country: "USA",
      niche: niches[i % niches.length],
      phone: phone,
      email: "demo#{n}@example.com",
      business_number: format("B9%05d", n),
      subscription: false,
      sold_price: nil,
      subscription_fee: nil
    )
  end
end
