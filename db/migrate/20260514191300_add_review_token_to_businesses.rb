class AddReviewTokenToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :review_token, :string
    add_index :businesses, :review_token, unique: true
  end
end
