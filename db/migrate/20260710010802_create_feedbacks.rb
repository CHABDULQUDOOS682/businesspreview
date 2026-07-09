class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.string :feedback_type, null: false, default: "general"
      t.string :priority, null: false, default: "medium"
      t.string :status, null: false, default: "pending"
      t.string :browser
      t.string :operating_system
      t.string :page_url
      t.text :steps_to_reproduce
      t.text :expected_result
      t.text :actual_result
      t.text :admin_notes
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :feedbacks, :feedback_type
    add_index :feedbacks, :priority
    add_index :feedbacks, :status
    add_index :feedbacks, :created_at
  end
end
