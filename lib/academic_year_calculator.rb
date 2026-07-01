module AcademicYearCalculator
  def current_academic_year
    Time.zone.today.month >= 8 ? Time.zone.today.year : Time.zone.today.year - 1
  end

  def next_academic_year
    current_academic_year + 1
  end

  def previous_academic_year
    current_academic_year - 1
  end

  def academic_year_for(date)
    date.month >= 8 ? date.year : date.year - 1
  end

  module_function :current_academic_year
  module_function :next_academic_year
  module_function :previous_academic_year
  module_function :academic_year_for
end
