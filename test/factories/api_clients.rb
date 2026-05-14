FactoryBot.define do
  factory :api_client do
    sequence(:name) { |n| Faker::Lorem.word + n.to_s }
    created_by { association :user }

    trait :with_authentication_token do
      after(:create) do |api_client|
        create(:authentication_token, api_client:)
      end
    end

    trait :discarded do
      discarded_at { Time.zone.now }
    end
  end
end
