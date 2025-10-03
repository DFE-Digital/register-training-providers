FactoryBot.define do
  factory :address do
    association :provider

    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    address_line_3 { nil }
    town_or_city { Faker::Address.city }
    county { Faker::Address.county }
    postcode { Faker::Address.postcode }

    trait :with_address_line_3 do
      address_line_3 { Faker::Address.building_number }
    end
  end
end
