class CreateAuthenticationTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :authentication_tokens, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :api_client, type: :uuid, null: false, foreign_key: true
      t.string :token_hash, null: false
      t.date :expires_at, null: false
      t.date :revoked_at
      t.datetime :last_used_at
      t.string :status, default: "active"
      t.references :created_by, type: :uuid, foreign_key: { to_table: :users }, null: false
      t.references :revoked_by, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :authentication_tokens, :token_hash, unique: true
    add_index :authentication_tokens, [:status, :last_used_at]
  end
end
