def current_academic_year
  Time.zone.now.month >= 8 ? Time.zone.now.year : Time.zone.now.year - 1
end
