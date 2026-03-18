class ChangeIndexOnApiClients < ActiveRecord::Migration[8.1]
  def up
    remove_index :api_clients, name: "index_api_clients_on_lower_name"
    execute "CREATE INDEX index_api_clients_on_created_by_and_lower_name ON api_clients(created_by_id, lower(name))"
  end

  def down
    remove_index :api_clients, name: "index_api_clients_on_created_by_and_lower_name"
    add_index :api_clients, "LOWER(name)", unique: true, name: "index_api_clients_on_lower_name"
  end
end
