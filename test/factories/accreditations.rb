FactoryBot.define do
  factory :accreditation do
    association :provider
    number { "#{Faker::Number.number(digits: 4)}" }
    start_date { 6.months.ago }
    end_date { 2.years.from_now }

    trait :current do
      start_date { 6.months.ago }
      end_date { 2.years.from_now }
    end

    trait :indefinite do
      start_date { 6.months.ago }
      end_date { nil }
    end

    trait :expired do
      start_date { 2.years.ago }
      end_date { 1.day.ago }
    end

    trait :future do
      start_date { 1.year.from_now }
      end_date { 3.years.from_now }
    end
  end
end
