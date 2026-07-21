class AddLinkUrlToPortfolioItems < ActiveRecord::Migration[8.0]
  def change
    add_column :portfolio_items, :link_url, :string
  end
end
