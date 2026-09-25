# frozen_string_literal: true

class RestorePhoneLookupToBusinesses < ActiveRecord::Migration[8.0]
  def change
    return if column_exists?(:businesses, :phone_line_type)

    add_column :businesses, :phone_line_type, :string
    add_column :businesses, :phone_lookup_checked_at, :datetime
    add_column :businesses, :phone_lookup_error, :string
  end
end
