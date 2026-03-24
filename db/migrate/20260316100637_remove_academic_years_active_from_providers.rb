class RemoveAcademicYearsActiveFromProviders < ActiveRecord::Migration[8.1]
  def up
    # remove_column :providers, :academic_years_active
  end

  def down
    # NOTE: not needed
  end
end
