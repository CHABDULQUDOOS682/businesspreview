# frozen_string_literal: true

class CreateAgencyTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :agency_tasks do |t|
      t.references :business, null: false, foreign_key: true
      t.string :source, null: false, default: "content_update"
      t.string :external_id, null: false
      t.string :business_number
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.string :external_url
      t.string :requester_name
      t.string :requester_email
      t.datetime :requested_at
      t.jsonb :raw_payload, default: {}, null: false

      t.timestamps
    end

    add_index :agency_tasks, [ :source, :external_id ], unique: true
    add_index :agency_tasks, :status
    add_index :agency_tasks, :business_number
  end
end
