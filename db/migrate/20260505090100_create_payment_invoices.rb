class CreatePaymentInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_invoices do |t|
      t.references :business, null: false, foreign_key: true
      t.string :kind, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "usd"
      t.string :status, null: false, default: "draft"
      t.integer :days_until_due, null: false, default: 30
      t.string :billing_interval, null: false, default: "month"
      t.string :delivery_method, null: false, default: "email"
      t.string :stripe_customer_id
      t.string :stripe_invoice_id
      t.string :stripe_subscription_id
      t.string :stripe_product_id
      t.string :stripe_price_id
      t.string :hosted_invoice_url
      t.string :invoice_pdf
      t.string :sent_to_email
      t.string :sent_to_phone
      t.datetime :sent_at
      t.datetime :paid_at
      t.text :last_error

      t.timestamps
    end

    add_index :payment_invoices, :kind
    add_index :payment_invoices, :status
    add_index :payment_invoices, :stripe_invoice_id, unique: true
    add_index :payment_invoices, :stripe_subscription_id
  end
end
