module ProviderChangeHelper
  def provider_field_level_history(changes)
    changes = changes.to_a

    changes.each_with_index.map do |change, index|
      effective_to = change_period_end(change, next_completed_change(changes, index))

      [
        format_change_value(change),
        display_change_date(change.effective_on),
        display_change_date(effective_to),
        change_credit(change),
        status_tag(change, effective_to)
      ]
    end
  end

  def display_change_date(date)
    return "" if date.blank?

    date.to_date.to_fs(:govuk)
  end

  def format_change_value(change)
    value = change.value
    return "Not entered" if value.blank?

    value
  end

private

  def next_completed_change(changes, index)
    changes[0...index].reverse.find(&:completed?)
  end

  def change_period_end(change, next_change)
    return if next_change.blank?

    [next_change.effective_on - 1.day, change.effective_on].max
  end

  def change_credit(change)
    return baseline_credit(change) if change.baseline?

    change.creator&.name || "Deleted user"
  end

  def baseline_credit(change)
    change.provider.audits.find_by(action: "create")&.user&.name || "Initial value"
  end

  def status_tag(change, effective_to)
    return govuk_tag(text: "Error", colour: "red") if change.failed?
    return govuk_tag(text: "Active", colour: "blue") if active_change?(change, effective_to)

    govuk_tag(text: "Inactive", colour: "grey")
  end

  def active_change?(change, effective_to)
    change.completed? &&
      change.effective_on <= Date.current &&
      change.value.to_s == current_value_for(change) &&
      (effective_to.nil? || Date.current <= effective_to)
  end

  def current_value_for(change)
    change.provider.public_send(change.attribute_name).to_s
  end
end
