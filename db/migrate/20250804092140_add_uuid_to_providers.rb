class AddUuidToProviders < ActiveRecord::Migration[8.0]
  def change
    add_column :providers, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_index :providers, :uuid, unique: true
  end
end
