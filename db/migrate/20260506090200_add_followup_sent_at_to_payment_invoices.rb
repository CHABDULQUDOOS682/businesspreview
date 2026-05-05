class AddFollowupSentAtToPaymentInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_invoices, :followup_sent_at, :datetime
  end
end
