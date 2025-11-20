FactoryBot.define do
  factory :api_client do
    name { Faker::App.unique.name }
  end
end
