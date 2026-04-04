class CreateBorrows < ActiveRecord::Migration[7.1]
  def change
    create_table :borrows do |t|
      t.references :asset,              null: false, foreign_key: true
      t.references :created_by,         null: true, foreign_key: { to_table: :users }
      t.references :approved_by,        null: true, foreign_key: { to_table: :users }
      t.string     :borrow_source,      null: false
      t.string     :borrower_type,      null: false
      t.string     :borrower_name,      null: false
      t.string     :borrower_identifier
      t.string     :borrower_group
      t.datetime   :starts_at,          null: false
      t.datetime   :ends_at,            null: false
      t.datetime   :returned_at
      t.string     :workflow_state,     null: false, default: "approved"
      t.text       :purpose
      t.text       :notes
      t.string     :import_batch
      t.integer    :import_row_number

      t.timestamps
    end

    add_index :borrows, :borrow_source
    add_index :borrows, :borrower_type
    add_index :borrows, :workflow_state
    add_index :borrows, :starts_at
    add_index :borrows, :ends_at
    add_index :borrows, :returned_at
  end
end
