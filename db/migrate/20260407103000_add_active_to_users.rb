class AddActiveToUsers < ActiveRecord::Migration[8.0]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_column :users, :active, :boolean, default: true, null: false

    MigrationUser.reset_column_information
    MigrationUser.update_all(active: true)
  end

  def down
    remove_column :users, :active
  end
end
