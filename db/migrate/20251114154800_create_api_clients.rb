class CreateApiClients < ActiveRecord::Migration[8.1]
  def change
    create_table :api_clients, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.datetime :discarded_at, index: true

      t.timestamps
    end

    add_index :api_clients, "LOWER(name)", unique: true, name: "index_api_clients_on_lower_name"
  end
end
