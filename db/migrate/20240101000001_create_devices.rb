class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :devices do |t|
      t.string  :code,            null: false
      t.string  :name,            null: false
      t.string  :device_type,     null: false
      t.string  :room,            null: false
      t.string  :brand
      t.string  :device_name
      t.string  :status,          null: false, default: "active"
      t.date    :imported_at
      t.date    :warranty_until
      t.integer :desk_number
      # Tech specs (optional – applicable to computers)
      t.string  :cpu
      t.string  :ram
      t.string  :storage
      t.string  :os
      t.string  :ip_address
      t.text    :notes

      t.timestamps
    end

    add_index :devices, :code,   unique: true
    add_index :devices, :status
    add_index :devices, :room
    add_index :devices, :device_type
  end
end
