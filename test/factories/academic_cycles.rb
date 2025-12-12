FactoryBot.define do
  factory :academic_cycle do
    duration do
      Time.zone.local(Time.zone.now.year, 8,
                      1).beginning_of_day...Time.zone.local(Time.zone.now.year + 1, 7, 31).end_of_day
    end
  end
end
