class CreatePortfolioItems < ActiveRecord::Migration[8.0]
  def change
    create_table :portfolio_items do |t|
      t.string :title, null: false
      t.string :category, null: false
      t.text :description
      t.string :metric
      t.string :accent_color, default: "from-[#213885]/30"
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :portfolio_items, :active
    add_index :portfolio_items, [ :active, :position ]
  end
end
