class AddSubscriptionBillingFields < ActiveRecord::Migration[8.0]
  def change
    change_table :businesses, bulk: true do |t|
      t.datetime :sold_price_paid_at
      t.datetime :subscription_billing_anchor_at
      t.datetime :next_subscription_invoice_at
      t.string :subscription_payment_status, default: "inactive", null: false
      t.datetime :subscription_grace_ends_at
      t.datetime :site_deactivated_at
      t.string :site_api_base_url
      t.string :site_api_secret
      t.string :site_external_id
    end

    change_table :payment_invoices, bulk: true do |t|
      t.date :billing_period_start
      t.date :billing_period_end
      t.integer :reminder_count, default: 0, null: false
      t.datetime :last_reminder_sent_at
    end

    add_index :businesses, :subscription_payment_status
    add_index :businesses, :next_subscription_invoice_at
    add_index :payment_invoices, [ :business_id, :billing_period_start ], unique: true, where: "billing_period_start IS NOT NULL"
  end
end
