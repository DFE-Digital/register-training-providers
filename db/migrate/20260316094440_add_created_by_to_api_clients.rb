class AddCreatedByToApiClients < ActiveRecord::Migration[8.1]
  def change
    add_reference :api_clients, :created_by, type: :uuid, foreign_key: { to_table: :users }
  end
end
