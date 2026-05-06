class BackfillPaymentInvoiceTokens < ActiveRecord::Migration[8.0]
  class MigrationPaymentInvoice < ApplicationRecord
    self.table_name = "payment_invoices"
  end

  def up
    MigrationPaymentInvoice.where(payment_token: nil).find_each do |invoice|
      invoice.update_columns(payment_token: unique_token)
    end

    change_column_null :payment_invoices, :payment_token, false
  end

  def down
    change_column_null :payment_invoices, :payment_token, true
  end

  private

  def unique_token
    loop do
      token = SecureRandom.base58(24)
      return token unless MigrationPaymentInvoice.exists?(payment_token: token)
    end
  end
end
