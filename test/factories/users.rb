FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    email { "#{first_name}.#{last_name}+test@education.gov.uk" }
  end
end
