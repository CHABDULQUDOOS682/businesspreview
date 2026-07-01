class AddUniqueIndexToBusinessesPhone < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE businesses
      SET phone = regexp_replace(phone, '[^0-9+]', '', 'g')
      WHERE phone IS NOT NULL;
    SQL

    add_index :businesses, "lower(phone)", unique: true, name: "index_businesses_on_lower_phone"
  end

  def down
    remove_index :businesses, name: "index_businesses_on_lower_phone"
  end
end
