class CreateProviderChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_changes, id: :uuid do |t|
      t.references :provider,
                   type: :uuid,
                   null: false,
                   index: false,
                   foreign_key: {
                     on_delete: :cascade
                   }

      t.string :attribute_name, null: false
      t.jsonb :value, null: false
      t.date :effective_on, null: false

      t.string :status, null: false, default: "pending"

      t.references :created_by,
                   type: :uuid,
                   null: true,
                   foreign_key: {
                     to_table: :users,
                     on_delete: :nullify
                   }
      t.datetime :processed_at
      t.text :error_message

      t.timestamps
    end

    add_index :provider_changes,
              [:provider_id, :attribute_name, :status, :effective_on]
  end
end
