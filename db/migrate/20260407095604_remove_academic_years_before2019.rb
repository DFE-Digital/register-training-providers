class RemoveAcademicYearsBefore2019 < ActiveRecord::Migration[8.1]
  def up
    cutoff_date = Date.new(2019, 8, 1)

    AcademicYear.where("lower(duration) < ?", cutoff_date).delete_all
  end

  def down
    # Irreversible unless you have a backup or seed logic
    raise ActiveRecord::IrreversibleMigration
  end
end
