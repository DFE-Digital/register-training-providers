module Generators
  class Partnerships < Base
    # Delegate to parent class attributes for backward compatibility
    alias_method :partnerships_created, :processed_count
    alias_method :total_training_partners, :total_count

  private

    def target_providers
      Provider.where(provider_type: ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.keys)
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

        accredited_period_end = accredited_period_start + 2.years

        academic_cycles = AcademicCycle.where("duration && daterange(?, ?)", accredited_period_start,
                                              accredited_period_end)

        partnership = Partnership.create!(
          provider: provider,
          accredited_provider: accredited_provider,
          duration: accredited_period_start...accredited_period_end
        )

        academic_cycles.each { |ac| PartnershipAcademicCycle.create(academic_cycle: ac, partnership: partnership) }
      end
    end
  end
end
