module Generators
  class Accreditations < Base
    # Delegate to parent class attributes for backward compatibility
    alias_method :providers_accredited, :processed_count
    alias_method :total_accreditable, :total_count

  private

    def target_providers
      Provider.where.not(provider_type: "school")
    end

    def existing_target_data_joins
      :accreditations
    end

    def process_provider(provider)
      create_accreditations_for_provider(provider)
    end

    def create_accreditations_for_provider(provider)
      prefix = accreditation_prefix_for(provider)
      num_accreditations = [1, 2].sample
      accreditations_created = 0

      if num_accreditations == 2
        create_expired_accreditation(provider, prefix)
        accreditations_created += 1
      end

      create_current_accreditation(provider, prefix)
      accreditations_created + 1
    end

    def accreditation_prefix_for(provider)
      case provider.provider_type
      when "hei"
        "1"
      when "scitt"
        "5"
      else
        ["1", "5"].sample
      end
    end

    def create_expired_accreditation(provider, prefix)
      provider.accreditations.create!(
        number: generate_accreditation_number(prefix),
        start_date: 3.years.ago,
        end_date: 6.months.ago
      )
    end

    def create_current_accreditation(provider, prefix)
      provider.accreditations.create!(
        number: generate_accreditation_number(prefix),
        start_date: 6.months.ago,
        end_date: 1.year.from_now
      )
    end

    def generate_accreditation_number(prefix)
      "#{prefix}#{rand(100..999)}"
    end
  end
end
