class AddOneTimeCommissionUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :commissions,
      :payment_invoice_id,
      unique: true,
      where: "month_number IS NULL",
      name: "index_commissions_on_one_time_invoice"
  end
end
