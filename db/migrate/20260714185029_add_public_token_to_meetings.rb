class AddPublicTokenToMeetings < ActiveRecord::Migration[8.0]
  def change
    add_column :meetings, :public_token, :string
    add_index :meetings, :public_token, unique: true
  end
end
