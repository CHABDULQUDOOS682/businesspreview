User.find_or_initialize_by(email: "super_admin@example.com").tap do |user|
  user.password = "Password@123"
  user.password_confirmation = "Password@123"
  user.role = "super_admin"
  user.save!
end
User.find_or_initialize_by(email: "admin@example.com").tap do |user|
  user.password = "Password@123"
  user.password_confirmation = "Password@123"
  user.role = "admin"
  user.save!
end
User.find_or_initialize_by(email: "employee@example.com").tap do |user|
  user.password = "Password@123"
  user.password_confirmation = "Password@123"
  user.role = "employee"
  user.save!
end