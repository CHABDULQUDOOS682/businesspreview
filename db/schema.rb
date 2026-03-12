# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_11_171651) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "businesses", force: :cascade do |t|
    t.string "name"
    t.string "owner_name"
    t.string "city"
    t.string "country"
    t.string "niche"
    t.string "phone"
    t.string "email"
    t.string "website_url"
    t.string "website_name"
    t.float "rating"
    t.text "message"
    t.decimal "sold_price", precision: 10, scale: 2
    t.decimal "subscription_fee", precision: 10, scale: 2
    t.boolean "subscription", default: false
    t.integer "visit_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.string "from_number"
    t.string "to_number"
    t.text "body"
    t.string "direction"
    t.bigint "business_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_messages_on_business_id"
  end

  create_table "preview_links", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "template"
    t.string "uuid"
    t.integer "visit_count", default: 0
    t.datetime "clicked_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_preview_links_on_business_id"
    t.index ["uuid"], name: "index_preview_links_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "messages", "businesses"
  add_foreign_key "preview_links", "businesses"
end
