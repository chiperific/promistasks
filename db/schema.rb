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

ActiveRecord::Schema.define(version: 20180429183602) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "google_id"
    t.string "selflink"
    t.string "title_number"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_id"], name: "index_properties_on_google_id", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.string "notes"
    t.string "status"
    t.string "google_id"
    t.datetime "due"
    t.datetime "completed"
    t.boolean "deleted"
    t.boolean "hidden"
    t.string "position", null: false
    t.string "parent_id"
    t.string "previous_id"
    t.bigint "property_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_id"], name: "index_tasks_on_google_id", unique: true
    t.index ["property_id"], name: "index_tasks_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name", null: false
    t.string "title"
    t.boolean "system_admin", default: false, null: false
    t.boolean "oauth_login", default: false, null: false
    t.boolean "program_staff", default: false, null: false
    t.boolean "project_staff", default: false, null: false
    t.boolean "admin_staff", default: false, null: false
    t.boolean "system_login", default: false, null: false
    t.boolean "client", default: false, null: false
    t.boolean "volunteer", default: false, null: false
    t.boolean "contractor", default: false, null: false
    t.string "phone1"
    t.string "phone2"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state", default: "MI"
    t.string "postal_code"
    t.integer "rate_cents", default: 0, null: false
    t.string "rate_currency", default: "USD", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "google_image_link"
    t.string "oauth_token"
    t.datetime "oauth_expires_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["oauth_token"], name: "index_users_on_oauth_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
