FactoryBot.define do
  factory :provider_change do
    association :provider
    association :creator, factory: :user

    code_change
    effective_on { Date.current }
    status { "pending" }

    trait :code_change do
      attribute_name { "code" }
      value { "ABC" }
    end

    trait :ukprn_change do
      attribute_name { "ukprn" }
      value { "10000001" }
    end

    trait :baseline do
      source { "baseline" }
      status { "completed" }
      creator { nil }
      processed_at { nil }
    end
  end
end
