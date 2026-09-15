module AcademicYearSpecHelper
  def build_academic_year_date(year = current_academic_year)
    Faker::Date.between(from: build_academic_year_start_date(year), to: build_academic_year_end_date(year))
  end

  def build_capped_current_academic_year_date
    year = current_academic_year

    Faker::Date.between(from: build_academic_year_start_date(year), to: Time.zone.now)
  end

  delegate :current_academic_year, to: :AcademicYearCalculator
  delegate :previous_academic_year, to: :AcademicYearCalculator
  delegate :academic_year_for, to: :AcademicYearCalculator
  delegate :build_academic_year_start_date, to: :AcademicYearCalculator
  delegate :build_academic_year_end_date, to: :AcademicYearCalculator
end
