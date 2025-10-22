FactoryBot.define do
  factory :contact do
    association :provider

    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email_address { Faker::Internet.email }
    telephone_number { Faker::PhoneNumber.phone_number }
  end
end
