class AddAcademicYearsActiveToProviders < ActiveRecord::Migration[8.1]
  def up
    add_column :providers, :academic_years_active, :integer, array: true, null: false, default: []
    add_index :providers, :academic_years_active, using: "gin"

    Provider.reset_column_information
    Provider.find_each do |provider|
      provider.update_column(:academic_years_active, [AcademicYearHelper.current_academic_year])
    end
  end

  def down
    remove_index :providers, :academic_years_active
    remove_column :providers, :academic_years_active
  end
end
