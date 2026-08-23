class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.references :business, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: "draft"
      t.string :title, null: false
      t.string :access_token, null: false
      t.string :client_name, null: false
      t.string :client_email, null: false
      t.string :agency_name, null: false, default: "DevDeBizz"
      t.text :scope_of_work, null: false
      t.text :pricing_terms, null: false
      t.text :timeline_terms, null: false
      t.text :termination_terms, null: false
      t.integer :amount_cents
      t.string :currency, default: "usd"
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.datetime :sent_at
      t.string :client_signer_name
      t.datetime :client_signed_at
      t.string :client_signer_ip
      t.text :client_signer_user_agent
      t.string :agency_signer_name
      t.datetime :agency_signed_at

      t.timestamps
    end

    add_index :contracts, :access_token, unique: true
    add_index :contracts, :status
  end
end
