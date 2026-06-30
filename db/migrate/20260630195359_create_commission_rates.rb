class CreateCommissionRates < ActiveRecord::Migration[8.0]
  def change
    create_table :commission_rates do |t|
      t.string  :kind, null: false           # "one_time" | "subscription"
      t.integer :month_number                # null for one_time, 1/2/3 for subscription
      t.decimal :percentage, precision: 5, scale: 2, null: false
      t.timestamps
    end
    add_index :commission_rates, [:kind, :month_number], unique: true
  end
end
