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

ActiveRecord::Schema[8.0].define(version: 2026_07_14_195434) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agency_tasks", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "source", default: "content_update", null: false
    t.string "external_id", null: false
    t.string "business_number"
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "pending", null: false
    t.string "external_url"
    t.string "requester_name"
    t.string "requester_email"
    t.datetime "requested_at"
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_agency_tasks_on_business_id"
    t.index ["business_number"], name: "index_agency_tasks_on_business_number"
    t.index ["source", "external_id"], name: "index_agency_tasks_on_source_and_external_id", unique: true
    t.index ["status"], name: "index_agency_tasks_on_status"
  end

  create_table "availability_rules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "day_of_week", null: false
    t.integer "start_minute", null: false
    t.integer "end_minute", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "day_of_week"], name: "index_availability_rules_on_user_id_and_day_of_week"
    t.index ["user_id"], name: "index_availability_rules_on_user_id"
  end

  create_table "business_commission_rates", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "kind", null: false
    t.integer "month_number"
    t.decimal "percentage", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "kind", "month_number"], name: "index_business_rates_on_business_kind_month", unique: true
    t.index ["business_id", "kind"], name: "index_business_rates_on_one_time_kind", unique: true, where: "(month_number IS NULL)"
    t.index ["business_id"], name: "index_business_commission_rates_on_business_id"
  end

  create_table "business_import_rows", force: :cascade do |t|
    t.bigint "business_import_id", null: false
    t.bigint "business_id"
    t.integer "row_number", null: false
    t.string "business_name"
    t.string "phone"
    t.string "status", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_business_import_rows_on_business_id"
    t.index ["business_import_id"], name: "index_business_import_rows_on_business_import_id"
    t.index ["status"], name: "index_business_import_rows_on_status"
  end

  create_table "business_imports", force: :cascade do |t|
    t.bigint "imported_by_id"
    t.string "filename"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["imported_by_id"], name: "index_business_imports_on_imported_by_id"
  end

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
    t.bigint "sold_by_id"
    t.string "business_location"
    t.datetime "sold_price_paid_at"
    t.datetime "subscription_billing_anchor_at"
    t.datetime "next_subscription_invoice_at"
    t.string "subscription_payment_status", default: "inactive", null: false
    t.datetime "subscription_grace_ends_at"
    t.datetime "site_deactivated_at"
    t.string "site_api_base_url"
    t.string "site_api_secret"
    t.string "site_external_id"
    t.string "business_number"
    t.index "lower((phone)::text)", name: "index_businesses_on_lower_phone", unique: true
    t.index ["business_number"], name: "index_businesses_on_business_number", unique: true
    t.index ["last_invoice_id"], name: "index_businesses_on_last_invoice_id"
    t.index ["next_subscription_invoice_at"], name: "index_businesses_on_next_subscription_invoice_at"
    t.index ["review_token"], name: "index_businesses_on_review_token", unique: true
    t.index ["sold_by_id"], name: "index_businesses_on_sold_by_id"
    t.index ["stripe_checkout_session_id"], name: "index_businesses_on_stripe_checkout_session_id"
    t.index ["stripe_customer_id"], name: "index_businesses_on_stripe_customer_id"
    t.index ["stripe_payment_intent_id"], name: "index_businesses_on_stripe_payment_intent_id"
    t.index ["stripe_subscription_id"], name: "index_businesses_on_stripe_subscription_id"
    t.index ["subscription_payment_status"], name: "index_businesses_on_subscription_payment_status"
  end

  create_table "call_logs", force: :cascade do |t|
    t.bigint "business_id"
    t.string "from_number"
    t.string "to_number"
    t.string "direction", default: "outbound", null: false
    t.string "status"
    t.integer "duration_seconds"
    t.string "twilio_call_sid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_call_logs_on_business_id"
    t.index ["created_at"], name: "index_call_logs_on_created_at"
    t.index ["direction"], name: "index_call_logs_on_direction"
    t.index ["twilio_call_sid"], name: "index_call_logs_on_twilio_call_sid", unique: true, where: "(twilio_call_sid IS NOT NULL)"
  end

  create_table "cold_calling_scripts", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.string "category"
    t.boolean "active", default: true, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_cold_calling_scripts_on_active"
    t.index ["category"], name: "index_cold_calling_scripts_on_category"
    t.index ["created_by_id"], name: "index_cold_calling_scripts_on_created_by_id"
  end

  create_table "commission_rates", force: :cascade do |t|
    t.string "kind", null: false
    t.integer "month_number"
    t.decimal "percentage", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "month_number"], name: "index_commission_rates_on_kind_and_month_number", unique: true
    t.index ["kind"], name: "index_commission_rates_on_one_time_kind", unique: true, where: "(month_number IS NULL)"
  end

  create_table "commissions", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "user_id", null: false
    t.bigint "payment_invoice_id", null: false
    t.string "kind", null: false
    t.integer "month_number"
    t.decimal "base_amount", precision: 10, scale: 2, null: false
    t.decimal "percentage", precision: 5, scale: 2, null: false
    t.decimal "commission_amount", precision: 10, scale: 2, null: false
    t.string "status", default: "pending", null: false
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.datetime "paid_out_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_commissions_on_approved_by_id"
    t.index ["business_id"], name: "index_commissions_on_business_id"
    t.index ["payment_invoice_id", "month_number"], name: "index_commissions_on_invoice_and_month", unique: true
    t.index ["payment_invoice_id"], name: "index_commissions_on_one_time_invoice", unique: true, where: "(month_number IS NULL)"
    t.index ["payment_invoice_id"], name: "index_commissions_on_payment_invoice_id"
    t.index ["status"], name: "index_commissions_on_status"
    t.index ["user_id"], name: "index_commissions_on_user_id"
  end

  create_table "employee_commission_rates", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.integer "month_number"
    t.decimal "percentage", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "kind", "month_number"], name: "index_employee_rates_on_user_kind_month", unique: true
    t.index ["user_id", "kind"], name: "index_employee_rates_on_one_time_kind", unique: true, where: "(month_number IS NULL)"
    t.index ["user_id"], name: "index_employee_commission_rates_on_user_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "feedback_type", default: "general", null: false
    t.string "priority", default: "medium", null: false
    t.string "status", default: "pending", null: false
    t.string "browser"
    t.string "operating_system"
    t.string "page_url"
    t.text "steps_to_reproduce"
    t.text "expected_result"
    t.text "actual_result"
    t.text "admin_notes"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_feedbacks_on_created_at"
    t.index ["feedback_type"], name: "index_feedbacks_on_feedback_type"
    t.index ["priority"], name: "index_feedbacks_on_priority"
    t.index ["status"], name: "index_feedbacks_on_status"
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "google_calendar_channels", force: :cascade do |t|
    t.string "channel_id", null: false
    t.string "resource_id", null: false
    t.datetime "expires_at", null: false
    t.string "sync_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_google_calendar_channels_on_channel_id", unique: true
  end

  create_table "meetings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "business_id", null: false
    t.string "client_name", null: false
    t.string "client_email", null: false
    t.string "client_phone"
    t.string "title", null: false
    t.text "description"
    t.datetime "starts_at", null: false
    t.integer "duration_minutes", default: 30, null: false
    t.string "google_event_id"
    t.string "google_meet_url"
    t.string "status", default: "scheduled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_token"
    t.index ["business_id", "starts_at"], name: "index_meetings_on_business_id_and_starts_at"
    t.index ["business_id"], name: "index_meetings_on_business_id"
    t.index ["google_event_id"], name: "index_meetings_on_google_event_id", unique: true, where: "(google_event_id IS NOT NULL)"
    t.index ["public_token"], name: "index_meetings_on_public_token", unique: true
    t.index ["starts_at"], name: "index_meetings_on_starts_at"
    t.index ["status"], name: "index_meetings_on_status"
    t.index ["user_id", "starts_at"], name: "index_meetings_on_user_id_and_starts_at"
    t.index ["user_id"], name: "index_meetings_on_user_id"
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
    t.bigint "user_id"
    t.index ["business_id"], name: "index_notes_on_business_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
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
    t.date "billing_period_start"
    t.date "billing_period_end"
    t.integer "reminder_count", default: 0, null: false
    t.datetime "last_reminder_sent_at"
    t.index ["business_id", "billing_period_start"], name: "index_payment_invoices_on_business_id_and_billing_period_start", unique: true, where: "(billing_period_start IS NOT NULL)"
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agency_tasks", "businesses"
  add_foreign_key "availability_rules", "users"
  add_foreign_key "business_commission_rates", "businesses"
  add_foreign_key "business_import_rows", "business_imports"
  add_foreign_key "business_import_rows", "businesses"
  add_foreign_key "business_imports", "users", column: "imported_by_id"
  add_foreign_key "businesses", "users", column: "sold_by_id"
  add_foreign_key "call_logs", "businesses"
  add_foreign_key "cold_calling_scripts", "users", column: "created_by_id"
  add_foreign_key "commissions", "businesses"
  add_foreign_key "commissions", "payment_invoices"
  add_foreign_key "commissions", "users"
  add_foreign_key "commissions", "users", column: "approved_by_id"
  add_foreign_key "employee_commission_rates", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "meetings", "businesses"
  add_foreign_key "meetings", "users"
  add_foreign_key "messages", "businesses"
  add_foreign_key "notes", "businesses"
  add_foreign_key "notes", "users"
  add_foreign_key "payment_invoices", "businesses"
  add_foreign_key "preview_links", "businesses"
  add_foreign_key "reviews", "businesses"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
