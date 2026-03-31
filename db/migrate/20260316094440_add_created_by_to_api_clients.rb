class AddCreatedByToApiClients < ActiveRecord::Migration[8.1]
  def up
    ApiClient.destroy_all

    add_reference :api_clients, :created_by, type: :uuid, foreign_key: { to_table: :users, on_delete: :cascade },
                                             null: false
  end

  def down
    remove_reference :api_clients, :created_by
  end
end
