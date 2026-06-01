class ChangeRoleToIntegerInUsers < ActiveRecord::Migration[8.0]
  def up
    change_column_default :users, :role, nil
    change_column :users, :role, :integer, using: "CASE WHEN role = 'employee' THEN 0 WHEN role = 'admin' THEN 1 WHEN role = 'super_admin' THEN 2 ELSE 0 END"
    change_column_default :users, :role, 0
  end

  def down
    change_column_default :users, :role, nil
    change_column :users, :role, :string, using: "CASE WHEN role = 0 THEN 'employee' WHEN role = 1 THEN 'admin' WHEN role = 2 THEN 'super_admin' ELSE 'employee' END"
    change_column_default :users, :role, 'employee'
  end
end
