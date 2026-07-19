# frozen_string_literal: true

class AddPhoneLookupToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :phone_line_type, :string
    add_column :businesses, :phone_lookup_checked_at, :datetime
    add_column :businesses, :phone_lookup_error, :string
  end
end
