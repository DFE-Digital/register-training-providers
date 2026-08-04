class AddRotpIdToProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :providers, :rotp_id, :string
    add_index :providers, :rotp_id, unique: true
  end
end
