class CreateBusinesses < ActiveRecord::Migration[8.0]
  def change
    create_table :businesses do |t|
      t.string :name
      t.string :owner_name
      t.string :city
      t.string :country
      t.string :niche
      t.string :phone
      t.string :email
      t.string :website_url
      t.string :website_name
      t.float :rating
      t.text :message
      t.decimal :sold_price, precision: 10, scale: 2
      t.decimal :subscription_fee, precision: 10, scale: 2
      t.boolean :subscription, default: false
      t.integer :visit_count, default: 0

      t.timestamps
    end
  end
end
