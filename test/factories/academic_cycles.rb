FactoryBot.define do
  factory :academic_cycle do
    transient do
      academic_year { Time.zone.now.year }
    end

    duration do
      Date.new(academic_year, 8, 1)..Date.new(academic_year + 1, 7, 31)
    end

    initialize_with do
      AcademicCycle.find_or_create_by!(duration:)
    end
  end
end
