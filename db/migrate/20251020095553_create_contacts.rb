class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table "contacts", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :provider_id, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email_address, null: false
      t.string :telephone_number, null: false
      t.datetime :discarded_at
      t.timestamps

      t.index [:provider_id], name: "index_contacts_on_provider_id"
      t.index [:created_at], name: "index_contacts_on_created_at"
      t.index [:discarded_at], name: "index_contacts_on_discarded_at"
    end

    add_foreign_key :contacts, :providers, column: :provider_id
  end
end
