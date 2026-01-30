module DataImporter
  class PartnershipService
    include ServicePattern

    def initialize(row)
      @row = row
    end

    def call
      ActiveRecord::Base.transaction do
        partnership = find_or_initialize_partnership

        assign_duration(partnership)

        partnership.save!(validate: false)

        attach_academic_cycles(partnership)

        partnership.save!(validate: false)

        attach_seed_data(partnership)
      end
    end

  private

    attr_reader :row

    def find_or_initialize_partnership
      Partnership.find_or_initialize_by(
        accredited_provider:,
        provider:
      )
    end

    def assign_duration(partnership)
      partnership.duration = duration_range
    end

    def attach_academic_cycles(partnership)
      academic_years.each do |year|
        cycle = AcademicCycle.for_year(year)

        partnership.partnership_academic_cycles
                   .find_or_create_by!(academic_cycle: cycle)
      end
    end

    def attach_seed_data(partnership)
      [accredited_provider, provider].each do |p|
        p.valid?

        p.seed_data_notes ||= {}
        p.seed_data_notes["partnership_imports"] ||= []

        p.seed_data_notes["partnership_imports"] << {
          row_imported: row_imported,
          saved_as: {
            partnership_id: partnership.id
          }
        }

        p.save!(validate: false)
      end
    end

    def accredited_provider
      @accredited_provider ||= Provider.find_by!(
        code: value("partnership__accredited_provider_provider_code")
      )
    end

    def provider
      @provider ||= Provider.find_by!(
        code: value("partnership__training_partner_provider_code")
      )
    end

    def duration_range
      start_date = parse_date(value("partnerships__duration_start"))
      end_date   = parse_date(value("partnerships__duration_end"))

      start_date..end_date
    end

    def academic_years
      v = value("partnership__academic_years_active")

      return [] if v.blank?

      return [] if v.blank?
      return [v] if v.is_a?(Integer)

      v.split(",").map(&:to_i)
    end

    def parse_date(raw)
      return nil if raw.blank?

      raw.is_a?(Date) ? raw : Date.parse(raw.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def value(key)
      row[key]
    end

    def row_imported
      {
        raw: row,
        accredited_provider_code: value("partnerships__accredited_provider_id_lookup_by_code"),
        provider_code: value("partnerships__provider_id_lookup_by_code"),
        duration: {
          start: value("partnerships__duration_start"),
          end: value("partnerships__duration_end")
        },
        academic_years: academic_years
      }
    end
  end
end
