FactoryBot.define do
  factory :academic_cycle do
    duration do
      current_year = Time.zone.now.year
      Date.new(current_year, 8, 1)...Date.new(current_year + 1, 7, 31)
    end
  end
end
