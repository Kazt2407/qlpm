class CreateWorkOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :work_orders do |t|
      t.references :asset, null: false, type: :bigint, foreign_key: true
      t.references :reported_by, null: true, type: :bigint, foreign_key: { to_table: :users }
      t.references :assigned_to, null: true, type: :bigint, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :priority, null: false, default: "normal"
      t.string :status, null: false, default: "open"
      t.date :due_on
      t.datetime :resolved_at
      t.decimal :cost, precision: 12, scale: 2
      t.text :resolution_notes

      t.timestamps
    end

    add_index :work_orders, :priority
    add_index :work_orders, :status
    add_index :work_orders, :due_on
    add_index :work_orders, :resolved_at
  end
end
