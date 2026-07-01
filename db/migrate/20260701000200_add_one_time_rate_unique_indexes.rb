class AddOneTimeRateUniqueIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :commission_rates,
      :kind,
      unique: true,
      where: "month_number IS NULL",
      name: "index_commission_rates_on_one_time_kind"

    add_index :employee_commission_rates,
      [ :user_id, :kind ],
      unique: true,
      where: "month_number IS NULL",
      name: "index_employee_rates_on_one_time_kind"

    add_index :business_commission_rates,
      [ :business_id, :kind ],
      unique: true,
      where: "month_number IS NULL",
      name: "index_business_rates_on_one_time_kind"
  end
end
