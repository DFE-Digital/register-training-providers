FactoryBot.define do
  factory :partnership_type do
    transient do
      partnership_type_value { PartnershipTypeEnum::TRAINING_AND_DELIVERY }
    end

    partnership do
      association(:partnership,
                  partnership_type: PartnershipTypeEnum::RECRUITMENT,
                  provider: association(:provider, :school))
    end

    partnership_type { partnership_type_value }
    source { "user" }
  end
end
