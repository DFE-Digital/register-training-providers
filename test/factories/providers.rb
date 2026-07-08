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

    onboarded_at { Date.current }
    first_active_at { Date.current }

    code { Faker::Alphanumeric.unique.alphanumeric(number: 3).upcase }
    ukprn { Faker::Number.unique.number(digits: 8).to_s }

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

    trait :with_inactive_period do
      after(:create) do |provider|
        if provider.inactive_periods.empty?
          previous_academic_year = create(:academic_year, :previous)

          provider.inactive_periods << { start_date: previous_academic_year.duration.begin,
                                         end_date: previous_academic_year.duration.end - 1.day,
                                         reason_for_inactive: "None given" }
          provider.save!
        end
      end
    end

    after(:create) do |provider|
      if provider.first_active_at.present?
        academic_year = create(:academic_year,
                               academic_year: AcademicYearCalculator.academic_year_for(provider.first_active_at))
        ProviderAcademicYear.find_or_create_by!(
          provider:,
          academic_year:
        )

        provider.onboarded_at = academic_year.duration.begin if provider.onboarded_at.blank?

      else
        academic_year = create(:academic_year, :current)
        ProviderAcademicYear.find_or_create_by!(
          provider:,
          academic_year:
        )

        provider.onboarded_at = academic_year.duration.begin if provider.onboarded_at.blank?
        provider.first_active_at = academic_year.duration.begin
      end
    end
  end
end
