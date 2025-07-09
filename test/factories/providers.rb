FactoryBot.define do
  factory :provider do
    provider_type { %i[school scitt hei other].sample }

    accreditation_status do
      if %i[school].include?(provider_type)
        :unaccredited
      else
        %i[accredited unaccredited].sample
      end
    end

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

    operating_name { [legal_name, Faker::Company.name].sample }

    urn do
      if %i[school scitt].include?(provider_type)
        Faker::Number.unique.number(digits: rand(5..6)).to_s
      end
    end

    code { Faker::Alphanumeric.alphanumeric(number: 3).upcase }
    ukprn { Faker::Number.unique.number(digits: 8).to_s }

    trait :archived do
      archived_at { Time.zone.now }
    end

    trait :discarded do
      discarded_at { Time.zone.now }
    end
  end
end
