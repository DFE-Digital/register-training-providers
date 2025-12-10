class CreateAcademicCycles < ActiveRecord::Migration[8.1]
  def change
    create_table :academic_cycles, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.daterange :duration
      t.datetime :discarded_at

      t.timestamps
    end
  end
end
