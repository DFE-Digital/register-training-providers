class AddCreatedByToApiClients < ActiveRecord::Migration[8.1]
  def change
    # rubocop:disable Rails/NotNullColumn
    add_reference :api_clients, :created_by, type: :uuid, foreign_key: { to_table: :users, on_delete: :cascade },
                                             null: false
    # rubocop:enable Rails/NotNullColumn
  end
end
