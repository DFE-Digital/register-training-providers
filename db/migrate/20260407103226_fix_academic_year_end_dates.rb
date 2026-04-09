class FixAcademicYearEndDates < ActiveRecord::Migration[8.1]
  def up
    AcademicYear.find_each do |ay|
      start_date = ay.duration.begin
      correct_end = Date.new(start_date.year + 1, 7, 31)

      ay.update_column(:duration, start_date..correct_end)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
