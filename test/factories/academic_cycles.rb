FactoryBot.define do
  factory :academic_cycle do
    current
    duration do
      Date.new(academic_year, 8, 1)..Date.new(academic_year + 1, 7, 31)
    end

    initialize_with do
      AcademicCycle.find_or_create_by!(duration:)
    end

    trait :current do
      transient do
        academic_year { AcademicYearHelper.current_academic_year }
      end
    end

    trait :next do
      transient do
        academic_year { AcademicYearHelper.next_academic_year }
      end
    end

    trait :previous do
      transient do
        academic_year { AcademicYearHelper.previous_academic_year }
      end
    end
  end
end
