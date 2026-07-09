class CreateMeetings < ActiveRecord::Migration[8.0]
  def change
    create_table :meetings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :business, null: false, foreign_key: true
      t.string :client_name, null: false
      t.string :client_email, null: false
      t.string :client_phone
      t.string :title, null: false
      t.text :description
      t.datetime :starts_at, null: false
      t.integer :duration_minutes, null: false, default: 30
      t.string :google_event_id
      t.string :google_meet_url
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end

    add_index :meetings, :status
    add_index :meetings, :starts_at
    add_index :meetings, :google_event_id, unique: true, where: "google_event_id IS NOT NULL"
    add_index :meetings, [ :user_id, :starts_at ]
    add_index :meetings, [ :business_id, :starts_at ]

    create_table :google_calendar_channels do |t|
      t.string :channel_id, null: false
      t.string :resource_id, null: false
      t.datetime :expires_at, null: false
      t.string :sync_token
      t.timestamps
    end

    add_index :google_calendar_channels, :channel_id, unique: true
  end
end
