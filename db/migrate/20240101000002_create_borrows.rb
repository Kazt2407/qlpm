class CreateBorrows < ActiveRecord::Migration[7.1]
  def change
    create_table :borrows do |t|
      t.references :device,         null: false, foreign_key: true
      t.string     :borrower_name,  null: false
      t.string     :borrower_class, null: false
      t.datetime   :borrowed_at,    null: false
      t.date       :due_at,         null: false
      t.datetime   :returned_at
      t.text       :purpose
      t.text       :notes

      t.timestamps
    end

    add_index :borrows, :returned_at
    add_index :borrows, :due_at
    add_index :borrows, :borrowed_at
  end
end
