module ProviderChangeHelper
  def provider_field_level_history(changes)
    changes = changes.to_a

    changes.each_with_index.map do |change, index|
      effective_to = change_period_end(change, next_completed_change(changes, index))

      cells = [
        format_change_value(change),
        display_change_date(change.effective_on),
        display_change_date(effective_to),
        change_credit(change),
        status_tag(change, effective_to)
      ]
      # The status history header is
      # ["Provider status", "Reason", "Start date", "End date", "Changed by",
      #  "Status"], and govuk_table maps cells to header columns positionally,
      # so reasons must sit in the second column.
      cells.insert(1, change_reasons(change)) if change.attribute_name == "status"
      cells
    end
  end

  def status_reason_legend(new_status)
    return "Why was the provider offboarded?" if new_status == ProviderStatusEnum::OFFBOARDED

    "Why did the provider become inactive?"
  end

  def status_effective_date_legend(new_status)
    return "When was the provider offboarded?" if new_status == ProviderStatusEnum::OFFBOARDED

    "When did the provider become #{new_status}?"
  end

  # Guidance for the status effective-date step. The wizard knows the earliest
  # date it will accept (the day the provider first existed), so surface it
  # rather than leaving the rule to be discovered by trial and error.
  def status_effective_date_hint(provider)
    earliest_date = ProviderStatusEnum.earliest_valid_date(provider)
    return "For example, 31 7 2026" if earliest_date.blank?

    "For example, 31 7 2026. The provider has existed since " \
      "#{earliest_date.to_fs(:govuk)}, so the date cannot be earlier."
  end

  def display_change_date(date)
    return "" if date.blank?

    date.to_date.to_fs(:govuk)
  end

  def format_change_value(change)
    value = change.value
    return format_blank_change_value(change) if value.blank?

    if change.attribute_name == "status"
      status_value = status_change_value(change)

      return format_blank_change_value(change) if status_value.blank?

      I18n.t("providers.statuses.#{status_value}")
    else
      value
    end
  end

private

  def change_reasons(change)
    return "" unless change.value.is_a?(Hash)

    ProviderStatusEnum.reason_labels_for(change.value["reason_ids"],
                                         change.value["other_reason"]).join(", ")
  end

  def format_blank_change_value(change)
    return "No URN recorded" if change.attribute_name == "urn"

    "Not entered"
  end

  def next_completed_change(changes, index)
    changes[0...index].reverse.find(&:completed?)
  end

  def change_period_end(change, next_change)
    return if next_change.blank?

    [next_change.effective_on - 1.day, change.effective_on].max
  end

  def change_credit(change)
    return baseline_credit(change) if change.baseline?
    return "System" if change.system?

    change.creator&.name || "Deleted user"
  end

  def baseline_credit(change)
    change.provider.audits.find_by(action: "create")&.user&.name || "Initial value"
  end

  def status_tag(change, effective_to)
    return govuk_tag(text: "Error", colour: "red") if change.failed?
    return status_row_tag(change, effective_to) if change.attribute_name == "status"
    return govuk_tag(text: "Active", colour: "blue") if active_change?(change, effective_to)

    govuk_tag(text: "Inactive", colour: "grey")
  end

  # Status rows carry the status itself in the first column, so an
  # Active/Inactive tag in the last column collides with the values and reads
  # as a second status. Describe the change instead: whether it is in force,
  # scheduled for the future, or superseded.
  def status_row_tag(change, effective_to)
    return govuk_tag(text: "Scheduled", colour: "yellow") if change.pending?
    return govuk_tag(text: "Current", colour: "blue") if active_change?(change, effective_to)

    govuk_tag(text: "Superseded", colour: "grey")
  end

  def active_change?(change, effective_to)
    change.completed? &&
      change.effective_on <= Date.current &&
      change_value_matches_provider_state?(change) &&
      (effective_to.nil? || Date.current <= effective_to)
  end

  def change_value_matches_provider_state?(change)
    if change.attribute_name == "status"
      status_change_value(change) == change.provider.status
    else
      change.value.to_s == current_value_for(change)
    end
  end

  def status_change_value(change)
    return nil unless change.value.is_a?(Hash)

    change.value["status"]
  end

  def current_value_for(change)
    change.provider.public_send(change.attribute_name).to_s
  end
end
