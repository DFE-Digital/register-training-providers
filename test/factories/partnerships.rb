FactoryBot.define do
  factory :partnership do
    transient do
      partnership_type { PartnershipTypeEnum::RECRUITMENT }
    end

    association :provider

    accredited_provider { create(:provider, :accredited) }
    duration { Date.new(Time.zone.now.year, 1, 1).. }

    after(:build) do |partnership, evaluator|
      if partnership.partnership_types.empty? && evaluator.partnership_type.present?
        partnership.partnership_types.build(
          partnership_type: evaluator.partnership_type,
          source: "user"
        )
      end
    end

    after(:create) do |partnership|
      create(:partnership_academic_year, partnership:)
    end

    trait :placement do
      partnership_type { PartnershipTypeEnum::PLACEMENT }
      provider { association(:provider, :school) }
    end
  end
end
