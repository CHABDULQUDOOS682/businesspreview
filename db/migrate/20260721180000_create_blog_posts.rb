class CreateBlogPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :category
      t.text :excerpt
      t.string :read_time_label
      t.date :published_on
      t.boolean :active, null: false, default: true
      t.string :meta_title
      t.string :meta_description

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :active
  end
end
