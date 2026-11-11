module PartnershipSteps
  extend ActiveSupport::Concern

  STEP_TITLES = {
    types: "Select partnership types",
    start_date: "Does the partnership start today?",
    end_date_question: "Does the partnership have an end date?",
    end_date: "When does the partnership end?",
    academic_years: "Select academic years",
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
    wizard.eligible_academic_years
  end

  def partnership_save_failure_message(partnership)
    type_messages = partnership.partnership_types.flat_map { |type| type.errors[:partnership_type] }
    messages = type_messages.presence || partnership.errors.full_messages

    messages.to_sentence.presence ||
      I18n.t("flash_message.alert.check.partnership.save_failed")
  end

end
