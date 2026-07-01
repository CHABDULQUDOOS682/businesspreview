FactoryBot.define do
  factory :business_import_row do
    business_import
    sequence(:row_number) { |n| n }
    business_name { "CSV Business" }
    phone { "+18005550199" }
    status { "created" }
  end
end
