class AddSoldByToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_reference :businesses, :sold_by, foreign_key: { to_table: :users }, null: true, index: true
  end
end
