module AcademicYearHelper
  def current_academic_year
    Time.zone.now.month >= 8 ? Time.zone.now.year : Time.zone.now.year - 1
  end

  def next_academic_year
    current_academic_year + 1
  end

  def previous_academic_year
    current_academic_year - 1
  end

  module_function :current_academic_year
  module_function :next_academic_year
  module_function :previous_academic_year
end
