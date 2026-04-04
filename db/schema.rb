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

ActiveRecord::Schema[7.2].define(version: 2024_01_01_000002) do
  create_table "borrows", force: :cascade do |t|
    t.integer "device_id", null: false
    t.string "borrower_name", null: false
    t.string "borrower_class", null: false
    t.datetime "borrowed_at", null: false
    t.date "due_at", null: false
    t.datetime "returned_at"
    t.text "purpose"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["borrowed_at"], name: "index_borrows_on_borrowed_at"
    t.index ["device_id"], name: "index_borrows_on_device_id"
    t.index ["due_at"], name: "index_borrows_on_due_at"
    t.index ["returned_at"], name: "index_borrows_on_returned_at"
  end

  create_table "devices", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "device_type", null: false
    t.string "room", null: false
    t.string "brand"
    t.string "device_name"
    t.string "status", default: "active", null: false
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
    t.index ["code"], name: "index_devices_on_code", unique: true
    t.index ["device_type"], name: "index_devices_on_device_type"
    t.index ["room"], name: "index_devices_on_room"
    t.index ["status"], name: "index_devices_on_status"
  end

  add_foreign_key "borrows", "devices"
end
