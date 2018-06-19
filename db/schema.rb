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

ActiveRecord::Schema.define(version: 20180610153731) do

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
    t.index ["property_id", "user_id"], name: "index_connections_on_property_id_and_user_id", unique: true
    t.index ["property_id"], name: "index_connections_on_property_id"
    t.index ["stage"], name: "index_connections_on_stage"
    t.index ["user_id", "property_id"], name: "index_connections_on_user_id_and_property_id", unique: true
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
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.string "city"
    t.string "state", default: "MI"
    t.string "postal_code"
    t.text "description"
    t.date "acquired_on"
    t.integer "cost_cents"
    t.string "cost_currency", default: "USD", null: false
    t.integer "lot_rent_cents"
    t.string "lot_rent_currency", default: "USD", null: false
    t.integer "budget_cents"
    t.string "budget_currency", default: "USD", null: false
    t.string "certificate_number"
    t.string "serial_number"
    t.integer "year_manufacture"
    t.string "manufacturer"
    t.string "model"
    t.string "certification_label1"
    t.string "certification_label2"
    t.bigint "creator_id", null: false
    t.boolean "is_private", default: false, null: false
    t.boolean "is_default", default: false, null: false
    t.boolean "created_from_api", default: false, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acquired_on"], name: "index_properties_on_acquired_on"
    t.index ["address"], name: "index_properties_on_address", unique: true
    t.index ["certificate_number"], name: "index_properties_on_certificate_number", unique: true
    t.index ["creator_id"], name: "index_properties_on_creator_id"
    t.index ["name"], name: "index_properties_on_name", unique: true
    t.index ["serial_number"], name: "index_properties_on_serial_number", unique: true
  end

  create_table "skill_tasks", force: :cascade do |t|
    t.bigint "skill_id", null: false
    t.bigint "task_id", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_skill_tasks_on_discarded_at"
    t.index ["skill_id", "task_id"], name: "index_skill_tasks_on_skill_id_and_task_id", unique: true
    t.index ["skill_id"], name: "index_skill_tasks_on_skill_id"
    t.index ["task_id", "skill_id"], name: "index_skill_tasks_on_task_id_and_skill_id", unique: true
    t.index ["task_id"], name: "index_skill_tasks_on_task_id"
  end

  create_table "skill_users", force: :cascade do |t|
    t.bigint "skill_id", null: false
    t.bigint "user_id", null: false
    t.boolean "is_licensed", default: false, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_skill_users_on_discarded_at"
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
    t.index ["name"], name: "index_skills_on_name", unique: true
  end

  create_table "task_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "task_id", null: false
    t.string "tasklist_gid", null: false
    t.string "google_id"
    t.string "position"
    t.bigint "position_int", default: 0
    t.string "parent_id"
    t.string "previous_id"
    t.boolean "deleted", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_id"], name: "index_task_users_on_google_id", unique: true
    t.index ["position_int"], name: "index_task_users_on_position_int"
    t.index ["task_id", "user_id"], name: "index_task_users_on_task_id_and_user_id", unique: true
    t.index ["task_id"], name: "index_task_users_on_task_id"
    t.index ["tasklist_gid"], name: "index_task_users_on_tasklist_gid"
    t.index ["user_id", "task_id"], name: "index_task_users_on_user_id_and_task_id", unique: true
    t.index ["user_id"], name: "index_task_users_on_user_id"
  end

  create_table "tasklists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.string "google_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_id"], name: "index_tasklists_on_google_id"
    t.index ["property_id", "user_id"], name: "index_tasklists_on_property_id_and_user_id", unique: true
    t.index ["property_id"], name: "index_tasklists_on_property_id"
    t.index ["user_id", "property_id"], name: "index_tasklists_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_tasklists_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.string "notes"
    t.string "priority"
    t.datetime "due"
    t.bigint "creator_id", null: false
    t.bigint "owner_id", null: false
    t.bigint "subject_id"
    t.bigint "property_id", null: false
    t.integer "budget_cents"
    t.string "budget_currency", default: "USD", null: false
    t.integer "cost_cents"
    t.string "cost_currency", default: "USD", null: false
    t.integer "visibility", default: 0, null: false
    t.boolean "license_required", default: false, null: false
    t.boolean "needs_more_info", default: false, null: false
    t.datetime "discarded_at"
    t.datetime "completed_at"
    t.boolean "created_from_api", default: false, null: false
    t.string "owner_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_tasks_on_creator_id"
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
    t.boolean "program_staff", default: false, null: false
    t.boolean "project_staff", default: false, null: false
    t.boolean "admin_staff", default: false, null: false
    t.boolean "client", default: false, null: false
    t.boolean "volunteer", default: false, null: false
    t.boolean "contractor", default: false, null: false
    t.integer "rate_cents", default: 0, null: false
    t.string "rate_currency", default: "USD", null: false
    t.string "phone1"
    t.string "phone2"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state", default: "MI"
    t.string "postal_code"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "system_admin", default: false, null: false
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["oauth_id"], name: "index_users_on_oauth_id", unique: true
    t.index ["oauth_token"], name: "index_users_on_oauth_token", unique: true
  end

  add_foreign_key "connections", "properties"
  add_foreign_key "connections", "users"
  add_foreign_key "skill_tasks", "skills"
  add_foreign_key "skill_tasks", "tasks"
  add_foreign_key "skill_users", "skills"
  add_foreign_key "skill_users", "users"
  add_foreign_key "task_users", "tasks"
  add_foreign_key "task_users", "users"
  add_foreign_key "tasklists", "properties"
  add_foreign_key "tasklists", "users"
end
