class AddBusinessLocationToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :business_location, :string
  end
end
