class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.string :from_number
      t.string :to_number
      t.text :body
      t.string :direction
      t.references :business, null: true, foreign_key: true

      t.timestamps
    end
  end
end
