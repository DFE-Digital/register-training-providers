class CreateProviders < ActiveRecord::Migration[8.0]
  def change
    create_table :providers do |t|
      t.string :operating_name
      t.string :legal_name
      t.string :ukprn, limit: 8, null: false
      t.string :urn, limit: 6
      t.string :code, limit: 3, null: false

      t.string :provider_type, null: false
      t.string :accreditation_status, null: false

      t.datetime :discarded_at
      t.timestamp :archived_at
      t.timestamps
    end

    add_index :providers, :ukprn
    add_index :providers, :urn

    add_index :providers, :code, unique: true
    add_index :providers, :provider_type
    add_index :providers, :accreditation_status
    add_index :providers, :legal_name

    add_index :providers, :discarded_at
    add_index :providers, :archived_at
  end
end
