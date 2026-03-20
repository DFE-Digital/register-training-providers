class BackfillProviderAcademicCycles < ActiveRecord::Migration[8.1]
  def up
    return unless column_exists?(:providers, :academic_years_active)

    Provider.find_each do |provider|
      Array(provider.academic_years_active).each do |year|
        academic_cycle = AcademicCycle.for_year(year)

        ProviderAcademicCycle.find_or_create_by!(
          provider:,
          academic_cycle:
        )
      end
    end
  end

  def down
    # NOTE: not needed
  end
end
