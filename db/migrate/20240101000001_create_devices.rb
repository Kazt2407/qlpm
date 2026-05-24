class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string  :full_name,       null: false
      t.string  :email,           null: false
      t.string  :role,            null: false, default: "user"
      t.string  :user_type,       null: false
      t.string  :password_digest
      t.string  :identifier
      t.string  :department
      t.boolean :active,          null: false, default: true

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :user_type

    create_table :rooms do |t|
      t.string  :code,       null: false
      t.string  :name,       null: false
      t.string  :room_type,  null: false, default: "computer_room"
      t.string  :status,     null: false, default: "active"
      t.integer :capacity
      t.string  :location
      t.text    :notes

      t.timestamps
    end

    add_index :rooms, :code, unique: true
    add_index :rooms, :room_type
    add_index :rooms, :status

    create_table :assets do |t|
      t.string     :code,           null: false
      t.string     :name,           null: false
      t.string     :asset_type,     null: false
      t.string     :category,       null: false
      t.references :room,           null: true, type: :bigint, foreign_key: true
      t.references :parent,         null: true, type: :bigint, foreign_key: { to_table: :assets }
      t.string     :status,         null: false, default: "active"
      t.string     :brand
      t.string     :model_code
      t.string     :serial_number
      t.date       :imported_at
      t.date       :warranty_until
      t.integer    :desk_number
      t.string     :cpu
      t.string     :ram
      t.string     :storage
      t.string     :os
      t.string     :ip_address
      t.text       :notes

      t.timestamps
    end

    add_index :assets, :code, unique: true
    add_index :assets, :asset_type
    add_index :assets, :category
    add_index :assets, :status
  end
end
