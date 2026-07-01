class CreateBusinessImports < ActiveRecord::Migration[8.0]
  def change
    create_table :business_imports do |t|
      t.references :imported_by, foreign_key: { to_table: :users }, null: true
      t.string :filename
      t.datetime :completed_at
      t.timestamps
    end

    create_table :business_import_rows do |t|
      t.references :business_import, null: false, foreign_key: true
      t.references :business, foreign_key: true, null: true
      t.integer :row_number, null: false
      t.string :business_name
      t.string :phone
      t.string :status, null: false
      t.text :reason
      t.timestamps
    end

    add_index :business_import_rows, :status
  end
end
