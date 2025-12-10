FactoryBot.define do
  factory :academic_cycle do
    duration { Time.zone.local(2025, 9, 1).beginning_of_day..Time.zone.local(2026, 8, 31).end_of_day }
  end
end
