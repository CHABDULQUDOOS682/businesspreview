class AddPackageKeyToContracts < ActiveRecord::Migration[8.0]
  def change
    add_column :contracts, :package_key, :string
    add_index :contracts, :package_key
  end
end
