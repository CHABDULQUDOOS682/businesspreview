class AddReadAtToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :read_at, :datetime
    add_index :messages, :read_at
  end
end
