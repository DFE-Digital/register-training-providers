module ProviderStatusEnum
  extend ActiveSupport::Concern

  PROVIDER_STATUSES = %i[active inactive offboarded].index_with(&:to_s).freeze

  ACTIVE = PROVIDER_STATUSES[:active]
  INACTIVE = PROVIDER_STATUSES[:inactive]
  OFFBOARDED = PROVIDER_STATUSES[:offboarded]

  ALLOWED_STATUS_TRANSITIONS = {
    active: %i[inactive offboarded],
    inactive: %i[active offboarded],
    offboarded: %i[active inactive]
  }.freeze

  REASONS_FOR_INACTIVE = {
    "no_current_cohorts" => "No current cohorts",
    "operations_temporarily_paused" => "Operations temporarily paused",
    "staffing_of_capacity_issues" => "Staffing or capacity issues",
    "financial_viability" => "Financial viability"
  }.freeze

  def self.reason_labels_for(reasons, other_reason_text)
    labels = Array(reasons).filter_map { |reason| REASONS_FOR_INACTIVE[reason] }
    labels << other_reason_text if Array(reasons).include?("other") && other_reason_text.present?

    labels
  end

  def self.earliest_valid_date(provider)
    [provider.first_active_at, provider.onboarded_at].compact.map(&:to_date).min
  end

  def self.effective_period_start(period)
    [period["start_date"], period["restored_at"]].compact.map(&:to_date).max
  end

  def self.period_conflicting_with_date(inactive_periods, date)
    inactive_periods.find { |period| date_conflicts_with_period?(period, date) }
  end

  def self.date_conflicts_with_period?(period, date)
    return date < period["start_date"].to_date if period["end_date"].nil?

    date <= period["end_date"].to_date
  end

  def status
    return "archived" if archived?
    return OFFBOARDED if open_offboarded_period.present?
    return INACTIVE if inactive?

    ACTIVE
  end

  def status_label
    I18n.t("providers.statuses.#{status}")
  end

  def allowed_status_transitions
    ALLOWED_STATUS_TRANSITIONS.fetch(status.to_sym, [])
  end

  def transitionable_status?(new_status)
    allowed_status_transitions.include?(new_status.to_sym)
  end

  def open_offboarded_period
    inactive_periods.find { |period| period["end_date"].nil? && period["offboarded"] }
  end

  def offboarded_period
    offboarded_periods.find { |period| period["end_date"].nil? } ||
      offboarded_periods.max_by { |period| period["start_date"] }
  end

  def offboarded_periods
    inactive_periods.select { |period| period["offboarded"] }
  end
end
