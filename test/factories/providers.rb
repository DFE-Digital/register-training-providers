FactoryBot.define do
  factory :provider do
    accredited

    legal_name do
      case provider_type.to_s
      when "school", "scitt"
        [Faker::Educator.secondary_school, Faker::Educator.primary_school].sample
      when "hei"
        Faker::Educator.university
      else
        Faker::Company.name
      end
    end

    operating_name { [legal_name, Faker::Company.name].compact.sample }

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

    trait :unaccredited do
      accreditation_status { :unaccredited }
      provider_type { ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.keys.sample }
    end

    trait :accredited do
      accreditation_status { :accredited }
      provider_type { ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.keys.sample }
    end
  end
end
