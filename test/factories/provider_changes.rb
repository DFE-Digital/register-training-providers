FactoryBot.define do
  factory :provider_change do
    association :provider

    code_change
    effective_on { Date.current }
    status { "pending" }

    trait :code_change do
      attribute_name { "code" }
      value { "ABC" }
    end
  end
end
