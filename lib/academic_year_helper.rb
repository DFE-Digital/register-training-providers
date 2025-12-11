module AcademicYearHelper
  def current_academic_year
    Time.zone.now.month >= 8 ? Time.zone.now.year : Time.zone.now.year - 1
  end

  module_function :current_academic_year
end
