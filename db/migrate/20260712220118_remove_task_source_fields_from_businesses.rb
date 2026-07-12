# frozen_string_literal: true

class RemoveTaskSourceFieldsFromBusinesses < ActiveRecord::Migration[8.0]
  def change
    remove_column :businesses, :task_source_enabled, :boolean, default: false, null: false
    remove_column :businesses, :task_base_url, :string
    remove_column :businesses, :task_secret, :string
    remove_column :businesses, :task_endpoint_path, :string, default: "/api/developer_tasks", null: false
  end
end
