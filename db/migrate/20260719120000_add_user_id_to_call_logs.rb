# frozen_string_literal: true

class AddUserIdToCallLogs < ActiveRecord::Migration[8.0]
  def up
    unless table_exists?(:call_logs)
      # Production never received a create_call_logs migration (table only lived in
      # local schema.rb). Create the full table so add_reference can succeed.
      create_table :call_logs do |t|
        t.references :business, null: true, foreign_key: true
        t.string :from_number
        t.string :to_number
        t.string :direction, null: false, default: "outbound"
        t.string :status
        t.integer :duration_seconds
        t.string :twilio_call_sid
        t.timestamps
      end

      add_index :call_logs, :created_at
      add_index :call_logs, :direction
      add_index :call_logs, :twilio_call_sid, unique: true, where: "(twilio_call_sid IS NOT NULL)"
    end

    add_reference :call_logs, :user, foreign_key: true, null: true unless column_exists?(:call_logs, :user_id)
  end

  def down
    remove_reference :call_logs, :user, foreign_key: true if column_exists?(:call_logs, :user_id)
  end
end
