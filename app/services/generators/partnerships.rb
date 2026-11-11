module Generators
  class Partnerships < Base
    # Delegate to parent class attributes for backward compatibility
    alias_method :partnerships_created, :processed_count
    alias_method :total_training_partners, :total_count

  private

    def target_providers
      Provider.where(accreditation_status: :unaccredited)
        .where.not(id: Accreditation.distinct.select(:provider_id))
    end

    def existing_target_data_joins
      :accrediting_provider_partnerships
    end

    def accredited_providers
      Provider.accredited
    end

    def process_provider(provider)
      create_partnerships_for_provider(provider)
    end

    def create_partnerships_for_provider(provider)
      accredited_providers.order("RANDOM()").limit(5).each do |accredited_provider|
        accredited_period_start = accredited_provider.accreditations.pluck(:start_date).min&.to_time
        next if accredited_period_start.blank?
        next if provider.partnerships.kept.current_or_scheduled.exists?(accredited_provider:)

        accredited_period_end = accredited_period_start + 2.years

        academic_years = AcademicYear.where("duration && daterange(?, ?)", accredited_period_start,
                                            accredited_period_end)

        partnership = Partnership.new(
          provider: provider,
          accredited_provider: accredited_provider,
          duration: accredited_period_start...accredited_period_end
        )
        partnership.apply_default_partnership_type(source: "generated")
        partnership.save!

        academic_years.each { |ac| PartnershipAcademicYear.create(academic_year: ac, partnership: partnership) }
      end
    end
  end
end
