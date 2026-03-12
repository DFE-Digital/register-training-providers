class CreateProviderAcademicCycles < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_academic_cycles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :provider, null: false, type: :uuid, foreign_key: true
      t.references :academic_cycle, null: false, type: :uuid, foreign_key: true

      t.datetime :discarded_at
      t.timestamps
    end

    add_index :provider_academic_cycles,
              [:provider_id, :academic_cycle_id],
              unique: true
  end
end
