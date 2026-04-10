FactoryBot.define do
  factory :provider do
    id { Faker::Internet.unique.uuid }
    hei_without_accreditation

    legal_name do
      n = Faker::Number.number(digits: 4)

      "#{I18n.t("providers.provider_types.#{provider_type}")} #{n}"
    end
    operating_name { legal_name }

    urn do
      if %i[school scitt].include?(provider_type.to_sym)
        Faker::Number.unique.number(digits: rand(5..6)).to_s
      end
    end

    code { Faker::Alphanumeric.unique.alphanumeric(number: 3).upcase }
    ukprn { Faker::Number.unique.number(digits: 8).to_s }

    with_current_academic_year

    trait :archived do
      archived_at { Time.zone.now }
    end

    trait :discarded do
      discarded_at { Time.zone.now }
    end

    trait :school do
      provider_type { :school }
      unaccredited
    end

    trait :scitt do
      provider_type { :scitt }
      accredited
    end

    trait :hei do
      provider_type { :hei }
      accredited
    end

    trait :hei_without_accreditation do
      provider_type { :hei }
      unaccredited
    end

    trait :other do
      provider_type { :other }
      accredited
    end

    trait :other_without_accreditation do
      provider_type { :other }
      unaccredited
    end

    trait :unaccredited do
      accreditation_status { :unaccredited }
    end

    trait :accredited do
      accreditation_status { :accredited }

      after(:create) do |provider|
        create(:accreditation, :current, provider:)
      end
    end

    trait :with_addresses do
      transient do
        address_count { 1 }
      end

      after(:create) do |provider, evaluator|
        create_list(:address, evaluator.address_count, provider:)
      end
    end

    trait :with_contacts do
      transient do
        contact_count { 1 }
      end

      after(:create) do |provider, evaluator|
        create_list(:contact, evaluator.contact_count, provider:)
      end
    end

    trait :with_address_issue do
      after(:create) do |provider|
        address = create(:address, provider:)

        provider.seed_data_notes = {
          "row_imported" => {
            "address" => address.attributes.to_json
          },
          "saved_as" => {
            provider_id: provider.id,
            accreditation_id: provider.accreditations.first&.id,
            address_id: nil,
          }
        }

        provider.save!
      end
    end

    trait :without_address_issue do
      after(:create) do |provider|
        address = create(:address, provider:)

        provider.seed_data_notes = {
          "row_imported" => {
            "address" => address.attributes.to_json
          },
          "saved_as" => {
            provider_id: provider.id,
            accreditation_id: provider.accreditations.first&.id,
            address_id: address.id,
          }
        }

        provider.save!
      end
    end

    trait :with_current_academic_year do
      after(:create) do |provider|
        if provider.academic_years.empty?
          academic_year = create(:academic_year, :current)

          ProviderAcademicYear.find_or_create_by!(
            provider:,
            academic_year:
          )
        end
      end
    end
  end
end
