class AddOnDeleteToAuthenticationTokensForeignKeys < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :authentication_tokens, column: :revoked_by_id
    add_foreign_key :authentication_tokens, :users, column: :revoked_by_id, on_delete: :nullify
  end
end
