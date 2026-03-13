FactoryBot.define do
  factory :api_client do
    sequence(:name) { |n| Faker::Lorem.word + n.to_s }

    trait :with_authentication_token do
      after(:create) do |api_client|
        create(:authentication_token, api_client:)
      end
    end
  end
end
