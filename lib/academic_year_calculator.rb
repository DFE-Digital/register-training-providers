module AcademicYearCalculator
  def current_academic_year
    Time.zone.today.month >= 8 ? Time.zone.today.year : Time.zone.today.year - 1
  end

  def following_academic_year
    current_academic_year + 2
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

  def build_academic_year_start_date(year)
    Date.new(year, 8, 1)
  end

  def build_academic_year_end_date(year)
    Date.new(year + 1, 7, 31)
  end

  module_function :current_academic_year
  module_function :next_academic_year
  module_function :following_academic_year
  module_function :previous_academic_year
  module_function :academic_year_for
  module_function :build_academic_year_start_date
  module_function :build_academic_year_end_date
end
