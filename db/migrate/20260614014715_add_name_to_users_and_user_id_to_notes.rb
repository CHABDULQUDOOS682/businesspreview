class AddNameToUsersAndUserIdToNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_reference :notes, :user, null: true, foreign_key: true
  end
end
