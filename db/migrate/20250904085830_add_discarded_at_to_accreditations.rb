class AddDiscardedAtToAccreditations < ActiveRecord::Migration[8.0]
  def change
    add_column :accreditations, :discarded_at, :datetime
    add_index :accreditations, :discarded_at
  end
end
