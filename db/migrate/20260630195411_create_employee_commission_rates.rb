class CreateEmployeeCommissionRates < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_commission_rates do |t|
      t.references :user, null: false, foreign_key: true   # the employee
      t.string  :kind, null: false
      t.integer :month_number
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.timestamps
    end
    add_index :employee_commission_rates, [:user_id, :kind, :month_number], unique: true,
      name: "index_employee_rates_on_user_kind_month"
  end
end
