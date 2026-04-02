FactoryBot.define do
  factory :academic_year do
    current
    duration do
      Date.new(academic_year, 8, 1)..Date.new(academic_year + 1, 7, 31)
    end

    initialize_with do
      AcademicYear.find_or_create_by!(duration:)
    end

    trait :current do
      transient do
        academic_year { AcademicYearCalculator.current_academic_year }
      end
    end

    trait :next do
      transient do
        academic_year { AcademicYearCalculator.next_academic_year }
      end
    end

    trait :previous do
      transient do
        academic_year { AcademicYearCalculator.previous_academic_year }
      end
    end
  end
end
