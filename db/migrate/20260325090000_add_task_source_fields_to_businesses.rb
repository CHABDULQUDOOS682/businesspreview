class AddTaskSourceFieldsToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :task_source_enabled, :boolean, default: false, null: false
    add_column :businesses, :task_base_url, :string
    add_column :businesses, :task_secret, :string
    add_column :businesses, :task_endpoint_path, :string, default: "/api/developer_tasks", null: false
  end
end
