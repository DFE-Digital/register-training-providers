module PartnershipSteps
  extend ActiveSupport::Concern

  STEP_TITLES = {
    types: "Select partnership types",
    dates: "Partnership dates",
    academic_years: "Academic year",
    check_your_answers: "Check your answers"
  }.freeze

private

  def template_for_step
    "providers/partnerships/journey/#{wizard.current_step_name}"
  end

  def page_title_for_step
    STEP_TITLES.fetch(wizard.current_step_name)
  end

  def eligible_academic_years
    start_date = wizard_state[:start_date]

    return AcademicYear.none if start_date.blank?

    end_date = wizard_state[:end_date] || default_end_date

    AcademicYear.where("duration && daterange(?, ?)", start_date, end_date).order(duration: :desc)
  end

  def default_end_date
    next_year = Time.zone.today + 1.year
    fallback = Time.zone.today + 2.years

    AcademicYear.find_by("duration @> ?::date", next_year)&.duration&.end || fallback
  end

  def partnership_save_failure_message(partnership)
    type_messages = partnership.partnership_types.flat_map { |type| type.errors[:partnership_type] }
    messages = type_messages.presence || partnership.errors.full_messages

    messages.to_sentence.presence ||
      I18n.t("flash_message.alert.check.partnership.save_failed")
  end

  def wizard_state
    wizard.state_store.read.with_indifferent_access
  end
end
