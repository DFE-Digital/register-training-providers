module ActivityHelper
  def group_audits_by_day(audits)
    audits.group_by { |audit| audit.created_at.in_time_zone.to_date }
  end
end

