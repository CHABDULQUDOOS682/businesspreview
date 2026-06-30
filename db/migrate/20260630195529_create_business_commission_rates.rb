class CreateBusinessCommissionRates < ActiveRecord::Migration[8.0]
  def change
    create_table :business_commission_rates do |t|
      t.references :business, null: false, foreign_key: true
      t.string  :kind, null: false
      t.integer :month_number
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.timestamps
    end
    add_index :business_commission_rates, [:business_id, :kind, :month_number], unique: true,
      name: "index_business_rates_on_business_kind_month"
  end
end
