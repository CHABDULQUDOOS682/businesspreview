class CreateAvailabilityRules < ActiveRecord::Migration[8.0]
  def change
    create_table :availability_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :day_of_week, null: false   # 0 = Sunday .. 6 = Saturday, matches Ruby Date#wday
      t.integer :start_minute, null: false  # minutes since midnight, e.g. 540 = 9:00am
      t.integer :end_minute, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :availability_rules, [ :user_id, :day_of_week ]
  end
end
