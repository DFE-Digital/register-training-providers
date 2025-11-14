class AddIndexContactEmail < ActiveRecord::Migration[8.0]
  def change
    add_index :contacts, [:email, :provider_id], unique: true
  end
end
