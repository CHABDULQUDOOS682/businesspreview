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
  { kind: "subscription", month_number: 3, percentage: 2.0 },
].each do |attrs|
  CommissionRate.find_or_create_by!(kind: attrs[:kind], month_number: attrs[:month_number]) do |r|
    r.percentage = attrs[:percentage]
  end
end
