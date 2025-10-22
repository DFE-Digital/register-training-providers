module Generators
  class Contacts < Base
    # Delegate to parent class attributes for backward compatibility
    alias_method :providers_contacted, :processed_count
    alias_method :total_contactable, :total_count

    # Ensure we're using the correct locale for UK addresses
    Faker::Config.locale = "en-GB" if defined?(Faker)

  private

    def target_providers
      Provider.all
    end

    def existing_target_data_joins
      :contacts
    end

    def process_provider(provider)
      num_contacts = [1, 2].sample
      num_contacts.times { create_contact_for_provider(provider) }
    end

    def clear_existing_data_for_providers(providers)
      provider_ids = providers.pluck(:id)
      Contact.where(provider_id: provider_ids).delete_all
    end

    def create_contact_for_provider(provider)
      provider.contacts.create!(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email_address: Faker::Internet.email,
        telephone_number: Faker::PhoneNumber.phone_number,
      )
    end
  end
end
