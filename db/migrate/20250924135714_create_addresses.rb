class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table "addresses", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :provider_id, null: false
      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :address_line_3
      t.string :town_or_city, null: false
      t.string :county
      t.string :postcode, null: false
      t.decimal :longitude, precision: 10, scale: 6
      t.decimal :latitude, precision: 10, scale: 6
      t.datetime :discarded_at
      t.timestamps

      t.index [:provider_id], name: "index_addresses_on_provider_id"
      t.index [:created_at], name: "index_addresses_on_created_at"
    end

    add_foreign_key :addresses, :providers, column: :provider_id
  end
end
