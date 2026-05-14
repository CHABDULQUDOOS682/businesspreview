class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :business, null: true, foreign_key: true
      t.string :client_name
      t.string :client_role
      t.text :content
      t.integer :rating, default: 5
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
