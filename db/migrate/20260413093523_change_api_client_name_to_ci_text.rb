class ChangeApiClientNameToCiText < ActiveRecord::Migration[8.1]
  def up
    change_column :api_clients, :name, :citext
    remove_index :api_clients, name: "index_api_clients_on_created_by_and_lower_name"
    add_index :api_clients,
              "created_by_id, name",
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_api_clients_on_created_by_and_name"
  end

  def down
    change_column :api_clients, :name, :string
    add_index :api_clients,
              "created_by_id, lower(name)",
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_api_clients_on_created_by_and_lower_name"
  end
end
