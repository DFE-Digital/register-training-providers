FactoryBot.define do
  factory :partnership_academic_year do
    association :partnership
    association :academic_year
  end
end
