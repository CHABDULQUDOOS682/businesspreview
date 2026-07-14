class CreateColdCallingScripts < ActiveRecord::Migration[8.0]
  def change
    create_table :cold_calling_scripts do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.string :category
      t.boolean :active, default: true, null: false
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :cold_calling_scripts, :active
    add_index :cold_calling_scripts, :category
  end
end
