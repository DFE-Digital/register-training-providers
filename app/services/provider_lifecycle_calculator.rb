class ProviderLifecycleCalculator
  include ServicePattern

  def initialize(academic_years)
    @academic_years = academic_years.sort_by { |ay| ay.duration.begin }
  end

  def call
    return empty_result if academic_years.empty?

    {
      onboarded_at: first_start_date,
      first_active_at: first_start_date,
      inactive_periods: inactive_periods,
    }
  end

private

  attr_reader :academic_years

  def empty_result
    {
      onboarded_at: nil,
      first_active_at: nil,
      inactive_periods: [],
    }
  end

  def first_start_date
    academic_years.first.duration.begin
  end

  def inactive_periods
    periods = academic_years.each_cons(2).filter_map do |previous, current|
      inactive_period_between(
        previous.duration.end + 1.day,
        current.duration.begin - 1.day,
      )
    end

    ongoing = ongoing_inactive_period
    periods << ongoing if ongoing

    periods
  end

  def ongoing_inactive_period
    last_active = academic_years.last

    return if last_active.current? || last_active.next?

    {
      start_date: last_active.duration.end + 1.day,
      end_date: nil,
      reason_for_inactive: reason_for_inactive,
    }
  end

  def inactive_period_between(start_date, end_date)
    return if start_date > end_date

    {
      start_date:,
      end_date:,
      reason_for_inactive:,
    }
  end

  def reason_for_inactive
    "None given"
  end
end
