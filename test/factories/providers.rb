FactoryBot.define do
  factory :provider do
    id { Faker::Internet.unique.uuid }
    provider_type { :hei }
    accreditation_status { :unaccredited }

    legal_name do
      loop do
        name = case provider_type.to_s
               when "school", "scitt"
                 [Faker::Educator.secondary_school, Faker::Educator.primary_school].sample
               when "hei"
                 Faker::Educator.university
               else
                 Faker::Company.name
               end
        break name unless name.include?("'")
      end
    end

    operating_name do
      loop do
        candidates = [legal_name, Faker::Company.name].compact.reject { |n| n.include?("'") }
        name = candidates.sample
        break name if name
      end
    end

    urn do
      if %i[school scitt].include?(provider_type.to_sym)
        Faker::Number.unique.number(digits: rand(5..6)).to_s
      end
    end

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
    end

    trait :other do
      provider_type { :other }
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
  end
end
