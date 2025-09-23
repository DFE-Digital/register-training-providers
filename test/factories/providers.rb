FactoryBot.define do
  factory :provider do
    provider_type { :hei }
    accreditation_status { :unaccredited }

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
  end
end
