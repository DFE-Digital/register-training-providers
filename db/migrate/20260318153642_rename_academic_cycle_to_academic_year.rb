class RenameAcademicCycleToAcademicYear < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :provider_academic_cycles, :academic_cycles
    remove_foreign_key :partnership_academic_cycles, :academic_cycles

    rename_table :academic_cycles, :academic_years

    rename_table :provider_academic_cycles, :provider_academic_years
    rename_table :partnership_academic_cycles, :partnership_academic_years

    rename_column :provider_academic_years,
                  :academic_cycle_id,
                  :academic_year_id

    rename_column :partnership_academic_years,
                  :academic_cycle_id,
                  :academic_year_id

    add_foreign_key :provider_academic_years, :academic_years
    add_foreign_key :partnership_academic_years, :academic_years
  end
end
