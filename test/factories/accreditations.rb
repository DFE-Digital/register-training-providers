FactoryBot.define do
  factory :accreditation do
    association :provider
    number do
      prefix = case provider&.provider_type&.to_s
               when "hei"
                 "1"
               when "scitt"
                 "5"
               when "other"
                 ["1", "5"].sample
               end
      "#{prefix}#{Faker::Number.number(digits: 3)}"
    end

    current

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
