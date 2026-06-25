module AcademicYearSpecHelper
  def build_academic_year_date(year = current_academic_year)
    Faker::Date.between(from: Date.new(year, 8, 1), to: Date.new(year + 1, 7, 31))
  end

  delegate :current_academic_year, to: :AcademicYearCalculator
  delegate :previous_academic_year, to: :AcademicYearCalculator
  delegate :academic_year_for, to: :AcademicYearCalculator
end
