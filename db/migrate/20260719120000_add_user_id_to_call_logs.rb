# frozen_string_literal: true

class AddUserIdToCallLogs < ActiveRecord::Migration[8.0]
  def change
    add_reference :call_logs, :user, foreign_key: true, null: true
  end
end
