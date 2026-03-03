class CreatePreviewLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :preview_links do |t|
      t.references :business, null: false, foreign_key: true
      t.string :template
      t.string :uuid, index: { unique: true }
      t.integer :visit_count, default: 0
      t.datetime :clicked_at
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
