module Generators
  class Addresses < Base
    # Delegate to parent class attributes for backward compatibility
    alias_method :providers_addressed, :processed_count
    alias_method :total_addressable, :total_count

    # Ensure we're using the correct locale for UK addresses
    Faker::Config.locale = "en-GB" if defined?(Faker)

  private

    def target_providers
      Provider.all
    end

    def existing_target_data_joins
      :addresses
    end

    def process_provider(provider)
      num_addresses = [1, 2].sample
      num_addresses.times { create_address_for_provider(provider) }
    end

    def clear_existing_data_for_providers(providers)
      provider_ids = providers.pluck(:id)
      Address.where(provider_id: provider_ids).delete_all
    end

    def create_address_for_provider(provider)
      provider.addresses.create!(
        address_line_1: Faker::Address.street_address,
        address_line_2: Faker::Address.secondary_address,
        town_or_city: Faker::Address.city,
        county: Faker::Address.county,
        postcode: Faker::Address.postcode,
        longitude: Faker::Address.longitude,
        latitude: Faker::Address.latitude
      )
    end
  end
end
