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

ActiveRecord::Schema[7.2].define(version: 2026_05_30_000001) do
  create_table "assets", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "asset_type", null: false
    t.string "category", null: false
    t.bigint "room_id"
    t.bigint "parent_id"
    t.string "status", default: "active", null: false
    t.string "brand"
    t.string "model_code"
    t.string "serial_number"
    t.date "imported_at"
    t.date "warranty_until"
    t.integer "desk_number"
    t.string "cpu"
    t.string "ram"
    t.string "storage"
    t.string "os"
    t.string "ip_address"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_type"], name: "index_assets_on_asset_type"
    t.index ["category"], name: "index_assets_on_category"
    t.index ["code"], name: "index_assets_on_code", unique: true
    t.index ["parent_id"], name: "index_assets_on_parent_id"
    t.index ["room_id"], name: "index_assets_on_room_id"
    t.index ["status"], name: "index_assets_on_status"
  end

  create_table "borrows", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.bigint "created_by_id"
    t.bigint "approved_by_id"
    t.string "borrow_source", null: false
    t.string "borrower_type", null: false
    t.string "borrower_name", null: false
    t.string "borrower_identifier"
    t.string "borrower_group"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.datetime "returned_at"
    t.string "workflow_state", default: "approved", null: false
    t.text "purpose"
    t.text "notes"
    t.string "import_batch"
    t.integer "import_row_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "approved_at"
    t.datetime "reminded_at"
    t.string "reminder_channel"
    t.index ["approved_at"], name: "index_borrows_on_approved_at"
    t.index ["approved_by_id"], name: "index_borrows_on_approved_by_id"
    t.index ["asset_id"], name: "index_borrows_on_asset_id"
    t.index ["borrow_source"], name: "index_borrows_on_borrow_source"
    t.index ["borrower_type"], name: "index_borrows_on_borrower_type"
    t.index ["created_by_id"], name: "index_borrows_on_created_by_id"
    t.index ["ends_at"], name: "index_borrows_on_ends_at"
    t.index ["reminded_at"], name: "index_borrows_on_reminded_at"
    t.index ["returned_at"], name: "index_borrows_on_returned_at"
    t.index ["starts_at"], name: "index_borrows_on_starts_at"
    t.index ["workflow_state"], name: "index_borrows_on_workflow_state"
  end

  create_table "rooms", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "room_type", default: "computer_room", null: false
    t.string "status", default: "active", null: false
    t.integer "capacity"
    t.string "location"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_rooms_on_code", unique: true
    t.index ["room_type"], name: "index_rooms_on_room_type"
    t.index ["status"], name: "index_rooms_on_status"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "role", default: "user", null: false
    t.string "user_type", null: false
    t.string "password_digest"
    t.string "identifier"
    t.string "department"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["user_type"], name: "index_users_on_user_type"
  end

  create_table "veyon_actions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "borrow_id"
    t.bigint "asset_id", null: false
    t.bigint "veyon_host_id"
    t.string "host", null: false
    t.string "feature_key", null: false
    t.string "status", default: "queued", null: false
    t.string "error_code"
    t.string "error_message"
    t.json "request_payload_json"
    t.json "response_payload_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_veyon_actions_on_asset_id"
    t.index ["borrow_id"], name: "index_veyon_actions_on_borrow_id"
    t.index ["created_at"], name: "index_veyon_actions_on_created_at"
    t.index ["feature_key"], name: "index_veyon_actions_on_feature_key"
    t.index ["host"], name: "index_veyon_actions_on_host"
    t.index ["status"], name: "index_veyon_actions_on_status"
    t.index ["user_id"], name: "index_veyon_actions_on_user_id"
    t.index ["veyon_host_id"], name: "index_veyon_actions_on_veyon_host_id"
  end

  create_table "veyon_hosts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.string "host", null: false
    t.integer "service_port", default: 11100, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "last_seen_at"
    t.json "metadata_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_veyon_hosts_on_asset_id"
    t.index ["enabled"], name: "index_veyon_hosts_on_enabled"
    t.index ["host", "service_port"], name: "index_veyon_hosts_on_host_and_service_port", unique: true
  end

  create_table "work_orders", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.bigint "reported_by_id"
    t.bigint "assigned_to_id"
    t.string "title", null: false
    t.text "description"
    t.string "priority", default: "normal", null: false
    t.string "status", default: "open", null: false
    t.date "due_on"
    t.datetime "resolved_at"
    t.decimal "cost", precision: 12, scale: 2
    t.text "resolution_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_work_orders_on_asset_id"
    t.index ["assigned_to_id"], name: "index_work_orders_on_assigned_to_id"
    t.index ["due_on"], name: "index_work_orders_on_due_on"
    t.index ["priority"], name: "index_work_orders_on_priority"
    t.index ["reported_by_id"], name: "index_work_orders_on_reported_by_id"
    t.index ["resolved_at"], name: "index_work_orders_on_resolved_at"
    t.index ["status"], name: "index_work_orders_on_status"
  end

  add_foreign_key "assets", "assets", column: "parent_id"
  add_foreign_key "assets", "rooms"
  add_foreign_key "borrows", "assets"
  add_foreign_key "borrows", "users", column: "approved_by_id"
  add_foreign_key "borrows", "users", column: "created_by_id"
  add_foreign_key "veyon_actions", "assets"
  add_foreign_key "veyon_actions", "borrows"
  add_foreign_key "veyon_actions", "users"
  add_foreign_key "veyon_actions", "veyon_hosts"
  add_foreign_key "veyon_hosts", "assets"
  add_foreign_key "work_orders", "assets"
  add_foreign_key "work_orders", "users", column: "assigned_to_id"
  add_foreign_key "work_orders", "users", column: "reported_by_id"
end
