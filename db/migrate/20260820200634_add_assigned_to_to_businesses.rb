class AddAssignedToToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_reference :businesses, :assigned_to, null: true, foreign_key: { to_table: :users }, index: true
    add_column :businesses, :assigned_at, :datetime
  end
end
