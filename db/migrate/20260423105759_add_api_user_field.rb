class AddApiUserField < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.column :api_user, :boolean, default: false, null: false
      t.column :active, :boolean, default: true, null: false
    end
  end
end
