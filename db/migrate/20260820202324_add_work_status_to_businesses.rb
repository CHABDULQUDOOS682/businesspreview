class AddWorkStatusToBusinesses < ActiveRecord::Migration[8.0]
  def up
    add_column :businesses, :work_status, :string
    add_column :businesses, :employee_report, :text
    add_column :businesses, :completion_notes, :text
    add_index :businesses, :work_status

    execute <<~SQL.squish
      UPDATE businesses
      SET work_status = 'assigned'
      WHERE assigned_to_id IS NOT NULL AND work_status IS NULL
    SQL
  end

  def down
    remove_index :businesses, :work_status
    remove_column :businesses, :completion_notes
    remove_column :businesses, :employee_report
    remove_column :businesses, :work_status
  end
end
