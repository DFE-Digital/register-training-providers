FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    email { "#{first_name}.#{last_name}+test@education.gov.uk" }

    trait :discarded do
      discarded_at { Time.zone.now }
    end

    trait :math_magician do
      id { 42 }
      first_name { "Mathilda" }
      last_name { "Mathmagician" }
    end
  end
end
