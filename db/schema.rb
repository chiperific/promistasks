# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_05_10_160150) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "auto_tasks", force: :cascade do |t|
    t.string "title", null: false
    t.string "notes"
    t.integer "position"
    t.integer "days_until_due", default: 0, null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["position"], name: "index_auto_tasks_on_position"
    t.index ["title"], name: "index_auto_tasks_on_title"
    t.index ["user_id"], name: "index_auto_tasks_on_user_id"
  end

  create_table "tasklists", force: :cascade do |t|
    t.string "google_id"
    t.string "title", null: false
    t.boolean "auto_tasks_created", default: false, null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["google_id"], name: "index_tasklists_on_google_id"
    t.index ["title"], name: "index_tasklists_on_title"
    t.index ["user_id"], name: "index_tasklists_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "oauth_provider"
    t.string "oauth_id"
    t.string "oauth_image_link"
    t.string "oauth_token"
    t.string "oauth_refresh_token"
    t.datetime "oauth_expires_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["oauth_id"], name: "index_users_on_oauth_id", unique: true
    t.index ["oauth_token"], name: "index_users_on_oauth_token", unique: true
  end

  add_foreign_key "auto_tasks", "users"
  add_foreign_key "tasklists", "users"
end
