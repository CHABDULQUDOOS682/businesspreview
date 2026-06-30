class CreateCommissions < ActiveRecord::Migration[8.0]
  def change
    create_table :commissions do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true            # employee who earns it
      t.references :payment_invoice, null: false, foreign_key: true
      t.string  :kind, null: false                                   # "one_time" | "subscription"
      t.integer :month_number                                        # null for one_time
      t.decimal :base_amount, precision: 10, scale: 2, null: false    # sold_price or monthly fee
      t.decimal :percentage, precision: 5, scale: 2, null: false      # rate actually used, locked
      t.decimal :commission_amount, precision: 10, scale: 2, null: false
      t.string  :status, null: false, default: "pending"              # pending|approved|paid_out|voided
      t.datetime :approved_at
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :paid_out_at
      t.timestamps
    end
    add_index :commissions, :status
    add_index :commissions, [:payment_invoice_id, :month_number], unique: true,
      name: "index_commissions_on_invoice_and_month"
  end
end
