class AddUprnToAddress < ActiveRecord::Migration[8.1]
  def change
    add_column :addresses, :uprn, :string, limit: 15
  end
end
