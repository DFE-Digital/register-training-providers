module ActivityHelper
  def group_audits_by_day(audits)
    audits.group_by { |audit| audit.created_at.to_date }
  end
end

