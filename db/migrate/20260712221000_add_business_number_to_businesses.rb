# frozen_string_literal: true

class AddBusinessNumberToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :business_number, :string
    add_index :businesses, :business_number, unique: true
  end
end
