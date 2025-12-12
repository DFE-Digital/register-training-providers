class CreatePartnershipAcademicCycles < ActiveRecord::Migration[8.1]
  def change
    create_table :partnership_academic_cycles do |t|
      t.references :partnership, type: :uuid, null: false, foreign_key: true
      t.references :academic_cycle, type: :uuid, null: false, foreign_key: true
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
