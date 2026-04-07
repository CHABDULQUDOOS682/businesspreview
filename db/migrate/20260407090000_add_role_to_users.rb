class AddRoleToUsers < ActiveRecord::Migration[8.0]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    add_column :users, :role, :string, default: "employee", null: false

    MigrationUser.reset_column_information
    MigrationUser.update_all(role: "employee")

    if (first_user = MigrationUser.order(:created_at, :id).first)
      first_user.update_columns(role: "super_admin")
    end
  end

  def down
    remove_column :users, :role
  end
end
