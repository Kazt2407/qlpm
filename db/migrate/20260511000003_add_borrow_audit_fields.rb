class AddBorrowAuditFields < ActiveRecord::Migration[7.1]
  def change
    add_column :borrows, :approved_at, :datetime
    add_column :borrows, :reminded_at, :datetime
    add_column :borrows, :reminder_channel, :string

    add_index :borrows, :approved_at
    add_index :borrows, :reminded_at
  end
end
