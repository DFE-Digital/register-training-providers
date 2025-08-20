module Accreditations
  class Generator
    include ServicePattern

    attr_reader :providers_accredited, :total_accreditable

    def initialize(percentage: 0.5)
      @percentage = percentage
      @providers_accredited = 0
      @total_accreditable = 0
    end

    def call
      @total_accreditable = accreditable_providers.count
      providers_to_accredit = accreditable_providers.order("RANDOM()").limit((@total_accreditable * @percentage).round)

      providers_to_accredit.each do |provider|
        next if provider.accreditations.exists?

        create_accreditations_for_provider(provider)
        @providers_accredited += 1
      end

      self
    end

  private

    def accreditable_providers
      Provider.where.not(provider_type: "school")
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
