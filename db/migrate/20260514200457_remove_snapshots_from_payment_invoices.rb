class RemoveSnapshotsFromPaymentInvoices < ActiveRecord::Migration[8.0]
  def change
    remove_column :payment_invoices, :invoice_snapshot_html, :text
    remove_column :payment_invoices, :receipt_snapshot_html, :text
  end
end
