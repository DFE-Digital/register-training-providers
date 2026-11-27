module DataImporter
  class PartnershipService
    include ServicePattern

    def initialize(row)
      @row = row
    end

    def call
      ActiveRecord::Base.transaction do
        partnership = find_or_initialize_partnership
        created = partnership.new_record?

        assign_duration(partnership)

        partnership.save!(validate: false)

        partnership.apply_default_partnership_type(source: "import").save! if created

        attach_academic_years(partnership)

        partnership.save!(validate: false)

        attach_seed_data(partnership)
      end
    end

  private

    attr_reader :row

    # A type revision leaves two kept rows for the same pair: the row it ended
    # and the replacement it started. `implicit_order_column` is `created_at`,
    # so an unordered lookup finds the ended row and the import would rewrite
    # history by moving those dates onto it; prefer the partnership that is
    # current now.
    def find_or_initialize_partnership
      Partnership.kept
                 .current_or_scheduled
                 .find_by(accredited_provider:, provider:) ||
        reimportable_historical_partnership ||
        Partnership.new(accredited_provider:, provider:)
    end

    # An import that describes a live partnership must never reopen one that
    # somebody ended: that erases the recorded ending and lets the ended row
    # reserve its partnership types again. Only reuse an ended row when the
    # imported period has ended too, so re-importing history stays idempotent.
    def reimportable_historical_partnership
      imported = duration_range
      return if imported.begin.nil? || imported.end.nil? || imported.end > Time.zone.today

      Partnership.kept
                 .ended
                 .where(accredited_provider:, provider:)
                 .where("lower(duration) = ?", imported.begin)
                 .first
    end

    def assign_duration(partnership)
      partnership.duration = duration_range
    end

    def attach_academic_years(partnership)
      academic_years.each do |year|
        cycle = AcademicYear.for_year(year)

        partnership.partnership_academic_years
                   .find_or_create_by!(academic_year: cycle)
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
      start_date = parse_date(value("partnership__start_date"))
      end_date   = parse_date(value("partnership__end_date"))

      start_date..end_date
    end

    def academic_years
      v = value("partnership__academic_years_active")

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
        accredited_provider_code: value("partnership__accredited_provider_provider_code"),
        provider_code: value("partnership__training_partner_provider_code"),
        duration: {
          start: value("partnership__start_date"),
          end: value("partnership__end_date")
        },
        academic_years: academic_years
      }
    end
  end
end
