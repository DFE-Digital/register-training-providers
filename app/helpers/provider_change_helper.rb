module ProviderChangeHelper
  def provider_field_level_history(changes)
    changes.each_with_index.map do |change, index|
      next_change = index.zero? ? nil : changes[index - 1]

      effective_from = change.effective_on
      effective_to = next_change&.effective_on&.-(1.day)

      [
        change.value,
        display_change_date(effective_from),
        display_change_date(effective_to),
        change.creator&.name || "Deleted user",
        status_tag(change, effective_to)
      ]
    end
  end

  def display_change_date(date)
    return "" if date.blank?

    date.to_date.to_fs(:govuk)
  end

private

  def status_tag(change, effective_to)
    return govuk_tag(text: "Error", colour: "red") if change.failed?
    return govuk_tag(text: "Active", colour: "blue") if active_code_change?(change, effective_to)

    govuk_tag(text: "Inactive", colour: "grey")
  end

  def active_code_change?(change, effective_to)
    change.completed? &&
      change.effective_on <= Date.current &&
      (effective_to.nil? || Date.current <= effective_to)
  end
end
