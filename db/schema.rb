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

ActiveRecord::Schema[8.0].define(version: 2026_05_14_200457) do
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
    t.boolean "task_source_enabled", default: false, null: false
    t.string "task_base_url"
    t.string "task_secret"
    t.string "task_endpoint_path", default: "/api/developer_tasks", null: false
    t.string "billing_email"
    t.string "stripe_customer_id"
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_payment_status"
    t.datetime "sold_at"
    t.string "stripe_subscription_id"
    t.string "stripe_subscription_status"
    t.datetime "subscription_started_at"
    t.datetime "subscription_current_period_end"
    t.string "last_invoice_id"
    t.string "last_invoice_status"
    t.datetime "last_invoice_paid_at"
    t.datetime "last_payment_failed_at"
    t.string "review_token"
    t.index ["last_invoice_id"], name: "index_businesses_on_last_invoice_id"
    t.index ["review_token"], name: "index_businesses_on_review_token", unique: true
    t.index ["stripe_checkout_session_id"], name: "index_businesses_on_stripe_checkout_session_id"
    t.index ["stripe_customer_id"], name: "index_businesses_on_stripe_customer_id"
    t.index ["stripe_payment_intent_id"], name: "index_businesses_on_stripe_payment_intent_id"
    t.index ["stripe_subscription_id"], name: "index_businesses_on_stripe_subscription_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "from_number"
    t.string "to_number"
    t.text "body"
    t.string "direction"
    t.bigint "business_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "read_at"
    t.index ["business_id"], name: "index_messages_on_business_id"
    t.index ["read_at"], name: "index_messages_on_read_at"
  end

  create_table "notes", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_notes_on_business_id"
  end

  create_table "payment_invoices", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "kind", null: false
    t.integer "amount_cents", null: false
    t.string "currency", default: "usd", null: false
    t.string "status", default: "draft", null: false
    t.integer "days_until_due", default: 30, null: false
    t.string "billing_interval", default: "month", null: false
    t.string "delivery_method", default: "email", null: false
    t.string "stripe_customer_id"
    t.string "stripe_invoice_id"
    t.string "stripe_subscription_id"
    t.string "stripe_product_id"
    t.string "stripe_price_id"
    t.string "hosted_invoice_url"
    t.string "invoice_pdf"
    t.string "sent_to_email"
    t.string "sent_to_phone"
    t.datetime "sent_at"
    t.datetime "paid_at"
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_token", null: false
    t.datetime "opened_at"
    t.string "receipt_url"
    t.datetime "followup_sent_at"
    t.index ["business_id"], name: "index_payment_invoices_on_business_id"
    t.index ["kind"], name: "index_payment_invoices_on_kind"
    t.index ["payment_token"], name: "index_payment_invoices_on_payment_token", unique: true
    t.index ["status"], name: "index_payment_invoices_on_status"
    t.index ["stripe_invoice_id"], name: "index_payment_invoices_on_stripe_invoice_id", unique: true
    t.index ["stripe_subscription_id"], name: "index_payment_invoices_on_stripe_subscription_id"
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

  create_table "reviews", force: :cascade do |t|
    t.bigint "business_id"
    t.string "client_name"
    t.string "client_role"
    t.text "content"
    t.integer "rating", default: 5
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_reviews_on_business_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "employee", null: false
    t.boolean "active", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "messages", "businesses"
  add_foreign_key "notes", "businesses"
  add_foreign_key "payment_invoices", "businesses"
  add_foreign_key "preview_links", "businesses"
  add_foreign_key "reviews", "businesses"
end
