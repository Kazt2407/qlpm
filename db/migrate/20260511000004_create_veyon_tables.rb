class CreateVeyonTables < ActiveRecord::Migration[7.2]
  def up
    unless table_exists?(:veyon_hosts)
      create_table :veyon_hosts do |t|
        t.references :asset, null: false, type: :bigint, foreign_key: true
        t.string :host, null: false
        t.integer :service_port, null: false, default: 11100
        t.boolean :enabled, null: false, default: true
        t.datetime :last_seen_at
        t.json :metadata_json

        t.timestamps
      end
    end

    add_index :veyon_hosts, [:host, :service_port], unique: true, if_not_exists: true
    add_index :veyon_hosts, :enabled, if_not_exists: true
    add_index :veyon_hosts, :asset_id, unique: true, if_not_exists: true

    unless table_exists?(:veyon_actions)
      create_table :veyon_actions do |t|
        t.references :user, null: false, type: :bigint, foreign_key: true
        t.references :borrow, null: true, type: :bigint, foreign_key: true
        t.references :asset, null: false, type: :bigint, foreign_key: true
        t.references :veyon_host, null: true, type: :bigint, foreign_key: true

        t.string :host, null: false
        t.string :feature_key, null: false
        t.string :status, null: false, default: "queued"
        t.string :error_code
        t.string :error_message
        t.json :request_payload_json
        t.json :response_payload_json

        t.timestamps
      end
    end

    add_index :veyon_actions, :host, if_not_exists: true
    add_index :veyon_actions, :feature_key, if_not_exists: true
    add_index :veyon_actions, :status, if_not_exists: true
    add_index :veyon_actions, :created_at, if_not_exists: true
  end

  def down
    drop_table :veyon_actions, if_exists: true
    drop_table :veyon_hosts, if_exists: true
  end
end
