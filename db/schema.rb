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

  create_table "tasklists", force: :cascade do |t|
    t.string "title", null: false
    t.string "google_id"
    t.string "selflink"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_id"], name: "index_tasklists_on_google_id", unique: true
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
    t.string "parent_id"
    t.string "previous_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_id"], name: "index_tasks_on_google_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.string "encrypted_password"
    t.string "google_image_link"
    t.string "oauth_token"
    t.datetime "oauth_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
