class CreatePartnerships < ActiveRecord::Migration[8.1]
  def change
    create_table :partnerships, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :provider, type: :uuid, null: false, foreign_key: true
      t.references :accredited_provider, type: :uuid, null: false, foreign_key: { to_table: :providers }
      t.daterange :duration
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
