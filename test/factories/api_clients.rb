FactoryBot.define do
  factory :api_client do
    name { Faker::App.unique.name }

    after(:create) do |api_client|
      create(:authentication_token, api_client:)
    end
  end
end
