class AddStripeCustomerToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :stripe_customer_id, :string unless column_exists?(:businesses, :stripe_customer_id)
    add_index :businesses, :stripe_customer_id unless index_exists?(:businesses, :stripe_customer_id)
  end
end
