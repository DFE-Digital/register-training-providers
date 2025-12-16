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

ActiveRecord::Schema[8.1].define(version: 2025_12_16_143104) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pgcrypto"

  create_table "academic_cycles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.daterange "duration"
    t.datetime "updated_at", null: false
    t.index ["duration"], name: "index_academic_cycles_on_duration"
  end

  create_table "accreditations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.date "end_date"
    t.string "number", null: false
    t.uuid "provider_id", null: false
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_accreditations_on_discarded_at"
    t.index ["end_date"], name: "index_accreditations_on_end_date"
    t.index ["number"], name: "index_accreditations_on_number"
    t.index ["provider_id"], name: "index_accreditations_on_provider_id"
    t.index ["start_date"], name: "index_accreditations_on_start_date"
  end

  create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "address_line_1", null: false
    t.string "address_line_2"
    t.string "address_line_3"
    t.string "county"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "postcode", null: false
    t.uuid "provider_id", null: false
    t.string "town_or_city", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_addresses_on_created_at"
    t.index ["provider_id"], name: "index_addresses_on_provider_id"
  end

  create_table "api_clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_api_clients_on_lower_name", unique: true
    t.index ["discarded_at"], name: "index_api_clients_on_discarded_at"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.jsonb "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "authentication_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "api_client_id", null: false
    t.datetime "created_at", null: false
    t.uuid "created_by_id", null: false
    t.date "expires_at", null: false
    t.datetime "last_used_at"
    t.date "revoked_at"
    t.uuid "revoked_by_id"
    t.string "status", default: "active"
    t.string "token_hash", null: false
    t.datetime "updated_at", null: false
    t.index ["api_client_id"], name: "index_authentication_tokens_on_api_client_id"
    t.index ["created_by_id"], name: "index_authentication_tokens_on_created_by_id"
    t.index ["revoked_by_id"], name: "index_authentication_tokens_on_revoked_by_id"
    t.index ["status", "last_used_at"], name: "index_authentication_tokens_on_status_and_last_used_at"
    t.index ["token_hash"], name: "index_authentication_tokens_on_token_hash", unique: true
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.uuid "provider_id", null: false
    t.string "telephone_number"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contacts_on_created_at"
    t.index ["discarded_at"], name: "index_contacts_on_discarded_at"
    t.index ["email", "provider_id"], name: "index_contacts_on_email_and_provider_id", unique: true
    t.index ["provider_id"], name: "index_contacts_on_provider_id"
  end

  create_table "partnership_academic_cycles", force: :cascade do |t|
    t.uuid "academic_cycle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.uuid "partnership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_cycle_id"], name: "index_partnership_academic_cycles_on_academic_cycle_id"
    t.index ["partnership_id"], name: "index_partnership_academic_cycles_on_partnership_id"
  end

  create_table "partnerships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "accredited_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.daterange "duration"
    t.uuid "provider_id", null: false
    t.datetime "updated_at", null: false
    t.index ["accredited_provider_id"], name: "index_partnerships_on_accredited_provider_id"
    t.index ["provider_id"], name: "index_partnerships_on_provider_id"
  end

  create_table "providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "accreditation_status", null: false
    t.datetime "archived_at", precision: nil
    t.citext "code", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "legal_name"
    t.string "operating_name", null: false
    t.string "provider_type", null: false
    t.tsvector "searchable"
    t.jsonb "seed_data_notes", default: {}, null: false
    t.boolean "seed_data_with_issues", default: false, null: false
    t.string "ukprn", limit: 8, null: false
    t.datetime "updated_at", null: false
    t.string "urn", limit: 6
    t.index ["accreditation_status"], name: "index_providers_on_accreditation_status"
    t.index ["archived_at"], name: "index_providers_on_archived_at"
    t.index ["code"], name: "index_providers_on_code", unique: true
    t.index ["discarded_at"], name: "index_providers_on_discarded_at"
    t.index ["legal_name"], name: "index_providers_on_legal_name"
    t.index ["provider_type"], name: "index_providers_on_provider_type"
    t.index ["searchable"], name: "index_providers_on_searchable", using: :gin
    t.index ["ukprn"], name: "index_providers_on_ukprn"
    t.index ["urn"], name: "index_providers_on_urn"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "temporary_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "created_by", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "expires_at", null: false
    t.string "purpose", default: "0", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by", "record_type", "purpose"], name: "index_temporary_records_on_created_by_record_type_purpose", unique: true
    t.index ["expires_at"], name: "index_temporary_records_on_expires_at"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dfe_sign_in_uid"
    t.datetime "discarded_at"
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "last_signed_in_at"
    t.boolean "system_admin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "accreditations", "providers"
  add_foreign_key "addresses", "providers"
  add_foreign_key "authentication_tokens", "api_clients"
  add_foreign_key "authentication_tokens", "users", column: "created_by_id"
  add_foreign_key "authentication_tokens", "users", column: "revoked_by_id", on_delete: :nullify
  add_foreign_key "contacts", "providers"
  add_foreign_key "partnership_academic_cycles", "academic_cycles"
  add_foreign_key "partnership_academic_cycles", "partnerships"
  add_foreign_key "partnerships", "providers"
  add_foreign_key "partnerships", "providers", column: "accredited_provider_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "temporary_records", "users", column: "created_by"
end
