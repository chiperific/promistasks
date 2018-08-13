# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_11_185130) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "connections", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "user_id", null: false
    t.string "relationship", null: false
    t.string "stage"
    t.date "stage_date"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_connections_on_discarded_at"
    t.index ["property_id"], name: "index_connections_on_property_id"
    t.index ["user_id"], name: "index_connections_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "identifier"
    t.string "record_type"
    t.integer "record_id"
    t.string "handler_class"
    t.integer "progress_current", default: 0, null: false
    t.integer "progress_max", default: 100, null: false
    t.string "message"
    t.string "error_message"
    t.datetime "completed_at"
    t.index ["completed_at"], name: "index_delayed_jobs_on_completed_at"
    t.index ["handler_class"], name: "index_delayed_jobs_on_handler_class"
    t.index ["identifier"], name: "index_delayed_jobs_on_identifier"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["record_type", "record_id"], name: "index_delayed_jobs_on_record_type_and_record_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", default: "Family Promise GR"
    t.string "domain", default: "familypromisegr.org"
    t.bigint "billing_contact_id"
    t.bigint "maintenance_contact_id"
    t.bigint "volunteer_contact_id"
    t.index ["billing_contact_id"], name: "index_organizations_on_billing_contact_id"
    t.index ["maintenance_contact_id"], name: "index_organizations_on_maintenance_contact_id"
    t.index ["volunteer_contact_id"], name: "index_organizations_on_volunteer_contact_id"
  end

  create_table "park_users", force: :cascade do |t|
    t.bigint "park_id", null: false
    t.bigint "user_id", null: false
    t.string "relationship", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["park_id", "user_id"], name: "index_park_users_on_park_id_and_user_id", unique: true
    t.index ["park_id"], name: "index_park_users_on_park_id"
    t.index ["user_id", "park_id"], name: "index_park_users_on_user_id_and_park_id", unique: true
    t.index ["user_id"], name: "index_park_users_on_user_id"
  end

  create_table "parks", force: :cascade do |t|
    t.string "name", null: false
    t.string "address"
    t.string "city"
    t.string "state", default: "MI"
    t.string "postal_code"
    t.text "notes"
    t.string "poc_name"
    t.string "poc_email"
    t.string "poc_phone"
    t.datetime "discarded_at"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_parks_on_discarded_at"
    t.index ["name"], name: "index_parks_on_name", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "property_id"
    t.bigint "park_id"
    t.bigint "utility_id"
    t.bigint "task_id"
    t.bigint "contractor_id"
    t.bigint "client_id"
    t.string "utility_type"
    t.string "utility_account"
    t.date "utility_service_started"
    t.text "notes"
    t.integer "bill_amt_cents", default: 0, null: false
    t.string "bill_amt_currency", default: "USD", null: false
    t.integer "payment_amt_cents"
    t.string "payment_amt_currency", default: "USD", null: false
    t.string "method"
    t.date "received"
    t.date "due"
    t.date "paid"
    t.boolean "recurring", default: false, null: false
    t.text "recurrence"
    t.boolean "send_email_reminders", default: false, null: false
    t.boolean "suppress_system_alerts", default: false, null: false
    t.datetime "discarded_at"
    t.bigint "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_payments_on_client_id"
    t.index ["contractor_id"], name: "index_payments_on_contractor_id"
    t.index ["creator_id"], name: "index_payments_on_creator_id"
    t.index ["discarded_at"], name: "index_payments_on_discarded_at"
    t.index ["park_id"], name: "index_payments_on_park_id"
    t.index ["property_id"], name: "index_payments_on_property_id"
    t.index ["task_id"], name: "index_payments_on_task_id"
    t.index ["utility_id"], name: "index_payments_on_utility_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "address"
    t.string "city"
    t.string "state", default: "MI"
    t.string "postal_code"
    t.text "description"
    t.date "acquired_on"
    t.bigint "park_id"
    t.integer "cost_cents"
    t.string "cost_currency", default: "USD", null: false
    t.integer "lot_rent_cents"
    t.string "lot_rent_currency", default: "USD", null: false
    t.integer "budget_cents"
    t.string "budget_currency", default: "USD", null: false
    t.string "stage", default: "acquired"
    t.date "expected_completion_date"
    t.date "actual_completion_date"
    t.string "certificate_number"
    t.string "serial_number"
    t.integer "year_manufacture"
    t.string "manufacturer"
    t.integer "beds", default: 1, null: false
    t.integer "baths", default: 1, null: false
    t.bigint "creator_id", null: false
    t.boolean "is_private", default: false, null: false
    t.boolean "is_default", default: false, null: false
    t.boolean "ignore_budget_warning", default: false, null: false
    t.boolean "created_from_api", default: false, null: false
    t.datetime "discarded_at"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acquired_on"], name: "index_properties_on_acquired_on"
    t.index ["address"], name: "index_properties_on_address", unique: true
    t.index ["creator_id"], name: "index_properties_on_creator_id"
    t.index ["discarded_at"], name: "index_properties_on_discarded_at"
    t.index ["name"], name: "index_properties_on_name", unique: true
    t.index ["park_id"], name: "index_properties_on_park_id"
  end

  create_table "skill_tasks", force: :cascade do |t|
    t.bigint "skill_id", null: false
    t.bigint "task_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id", "task_id"], name: "index_skill_tasks_on_skill_id_and_task_id", unique: true
    t.index ["skill_id"], name: "index_skill_tasks_on_skill_id"
    t.index ["task_id", "skill_id"], name: "index_skill_tasks_on_task_id_and_skill_id", unique: true
    t.index ["task_id"], name: "index_skill_tasks_on_task_id"
  end

  create_table "skill_users", force: :cascade do |t|
    t.bigint "skill_id", null: false
    t.bigint "user_id", null: false
    t.boolean "is_licensed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id", "user_id"], name: "index_skill_users_on_skill_id_and_user_id", unique: true
    t.index ["skill_id"], name: "index_skill_users_on_skill_id"
    t.index ["user_id", "skill_id"], name: "index_skill_users_on_user_id_and_skill_id", unique: true
    t.index ["user_id"], name: "index_skill_users_on_user_id"
  end

  create_table "skills", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "license_required", default: false, null: false
    t.boolean "volunteerable", default: true, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_skills_on_discarded_at"
    t.index ["name"], name: "index_skills_on_name", unique: true
  end

  create_table "task_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "task_id", null: false
    t.string "scope"
    t.string "tasklist_gid", null: false
    t.string "google_id"
    t.boolean "deleted", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scope"], name: "index_task_users_on_scope"
    t.index ["task_id", "user_id"], name: "index_task_users_on_task_id_and_user_id", unique: true
    t.index ["task_id"], name: "index_task_users_on_task_id"
    t.index ["user_id", "task_id"], name: "index_task_users_on_user_id_and_task_id", unique: true
    t.index ["user_id"], name: "index_task_users_on_user_id"
  end

  create_table "tasklists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.string "google_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "user_id"], name: "index_tasklists_on_property_id_and_user_id", unique: true
    t.index ["property_id"], name: "index_tasklists_on_property_id"
    t.index ["user_id", "property_id"], name: "index_tasklists_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_tasklists_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.string "notes"
    t.integer "priority"
    t.date "due"
    t.bigint "creator_id", null: false
    t.bigint "owner_id", null: false
    t.bigint "subject_id"
    t.bigint "property_id", null: false
    t.integer "budget_cents"
    t.string "budget_currency", default: "USD", null: false
    t.integer "cost_cents"
    t.string "cost_currency", default: "USD", null: false
    t.integer "visibility", default: 0, null: false
    t.boolean "needs_more_info", default: false, null: false
    t.datetime "discarded_at"
    t.datetime "completed_at"
    t.boolean "created_from_api", default: false, null: false
    t.boolean "volunteer_group", default: false, null: false
    t.boolean "professional", default: false, null: false
    t.integer "min_volunteers", default: 0, null: false
    t.integer "max_volunteers", default: 0, null: false
    t.integer "actual_volunteers"
    t.float "estimated_hours"
    t.float "actual_hours"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_tasks_on_creator_id"
    t.index ["discarded_at"], name: "index_tasks_on_discarded_at"
    t.index ["owner_id"], name: "index_tasks_on_owner_id"
    t.index ["property_id", "title"], name: "index_tasks_on_property_id_and_title", unique: true
    t.index ["property_id"], name: "index_tasks_on_property_id"
    t.index ["subject_id"], name: "index_tasks_on_subject_id"
    t.index ["title", "property_id"], name: "index_tasks_on_title_and_property_id", unique: true
    t.index ["title"], name: "index_tasks_on_title"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "title"
    t.string "phone", null: false
    t.boolean "admin", default: false, null: false
    t.boolean "staff", default: false, null: false
    t.boolean "client", default: false, null: false
    t.boolean "volunteer", default: false, null: false
    t.boolean "contractor", default: false, null: false
    t.integer "rate_cents", default: 0, null: false
    t.string "rate_currency", default: "USD", null: false
    t.integer "adults", default: 1, null: false
    t.integer "children", default: 0, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "oauth_provider"
    t.string "oauth_id"
    t.string "oauth_image_link"
    t.string "oauth_token"
    t.string "oauth_refresh_token"
    t.datetime "oauth_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["oauth_token"], name: "index_users_on_oauth_token", unique: true
  end

  create_table "utilities", force: :cascade do |t|
    t.string "name"
    t.text "notes"
    t.string "address"
    t.string "city"
    t.string "state", default: "MI"
    t.string "postal_code"
    t.string "poc_name"
    t.string "poc_email"
    t.string "poc_phone"
    t.datetime "discarded_at"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_utilities_on_discarded_at"
    t.index ["name"], name: "index_utilities_on_name", unique: true
  end

  add_foreign_key "connections", "properties"
  add_foreign_key "connections", "users"
  add_foreign_key "park_users", "parks"
  add_foreign_key "park_users", "users"
  add_foreign_key "payments", "parks"
  add_foreign_key "payments", "properties"
  add_foreign_key "payments", "tasks"
  add_foreign_key "payments", "utilities"
  add_foreign_key "skill_tasks", "skills"
  add_foreign_key "skill_tasks", "tasks"
  add_foreign_key "skill_users", "skills"
  add_foreign_key "skill_users", "users"
  add_foreign_key "task_users", "tasks"
  add_foreign_key "task_users", "users"
  add_foreign_key "tasklists", "properties"
  add_foreign_key "tasklists", "users"
end
