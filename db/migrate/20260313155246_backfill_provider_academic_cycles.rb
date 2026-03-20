class BackfillProviderAcademicCycles < ActiveRecord::Migration[8.1]
  class AcademicCycle < ApplicationRecord
    self.table_name = "academic_cycles"

    def self.for_year(year)
      find_by(duration: Date.new(year, 8, 1)..Date.new(year + 1, 7, 31))
    end
  end

  class ProviderAcademicCycle < ApplicationRecord
    self.table_name = "provider_academic_cycles"
  end

  class Provider < ApplicationRecord
    self.table_name = "providers"
  end

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
