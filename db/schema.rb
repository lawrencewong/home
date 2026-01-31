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

ActiveRecord::Schema[8.1].define(version: 2026_01_31_182534) do
  create_table "appliances", force: :cascade do |t|
    t.string "brand"
    t.datetime "created_at", null: false
    t.string "location"
    t.string "manual_url"
    t.string "model_number"
    t.string "name", null: false
    t.text "notes"
    t.date "purchase_date"
    t.string "serial_number"
    t.datetime "updated_at", null: false
    t.date "warranty_expires"
  end

  create_table "reminders", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.date "due_date", null: false
    t.string "recurrence_rule"
    t.integer "remindable_id"
    t.string "remindable_type"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["completed_at"], name: "index_reminders_on_completed_at"
    t.index ["created_by_id"], name: "index_reminders_on_created_by_id"
    t.index ["due_date"], name: "index_reminders_on_due_date"
    t.index ["remindable_type", "remindable_id"], name: "index_reminders_on_remindable"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "archived_at"
    t.integer "assigned_to_id"
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.date "due_date"
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_tasks_on_assigned_to_id"
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["status"], name: "index_tasks_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", default: "", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "wiki_pages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by_id", null: false
    t.index ["created_by_id"], name: "index_wiki_pages_on_created_by_id"
    t.index ["title"], name: "index_wiki_pages_on_title", unique: true
    t.index ["updated_by_id"], name: "index_wiki_pages_on_updated_by_id"
  end

  create_table "wishlist_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.integer "item_type", default: 0, null: false
    t.string "link"
    t.text "notes"
    t.decimal "price", precision: 10, scale: 2
    t.integer "priority", default: 1, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_wishlist_items_on_created_by_id"
    t.index ["item_type"], name: "index_wishlist_items_on_item_type"
    t.index ["priority"], name: "index_wishlist_items_on_priority"
  end

  add_foreign_key "reminders", "users", column: "created_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "tasks", "users", column: "assigned_to_id"
  add_foreign_key "tasks", "users", column: "created_by_id"
  add_foreign_key "wiki_pages", "users", column: "created_by_id"
  add_foreign_key "wiki_pages", "users", column: "updated_by_id"
  add_foreign_key "wishlist_items", "users", column: "created_by_id"
end
