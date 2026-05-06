class AddTrackingAndDocumentsToPaymentInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_invoices, :payment_token, :string
    add_column :payment_invoices, :opened_at, :datetime
    add_column :payment_invoices, :receipt_url, :string
    add_column :payment_invoices, :invoice_snapshot_html, :text
    add_column :payment_invoices, :receipt_snapshot_html, :text

    add_index :payment_invoices, :payment_token, unique: true
  end
end
