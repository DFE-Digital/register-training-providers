module AccreditationHelper
  def accreditation_form_rows(accreditation_form, change_path = nil)
    return [] unless accreditation_form&.valid?

    change_path ||= new_provider_accreditation_path(goto: "confirm")

    dates_row = accreditation_dates_row(accreditation_form.start_date, accreditation_form.end_date)
    dates_row[:actions] = [{ href: change_path, visually_hidden_text: "accreditation dates" }]

    [
      { key: { text: "Accredited provider number" },
        value: { text: accreditation_form.number },
        actions: [{ href: change_path, visually_hidden_text: "accredited provider number" }] },
      dates_row
    ]
  end

  def accreditation_rows(accreditation, change_path = nil)
    rows = [
      { key: { text: "Accredited provider number" },
        value: { text: accreditation.number } },
      accreditation_dates_row(accreditation.start_date, accreditation.end_date),
    ]

    if change_path
      rows[0][:actions] = [{ href: change_path, visually_hidden_text: "accredited provider number" }]
      rows[1][:actions] = [{ href: change_path, visually_hidden_text: "accreditation dates" }]
    end

    rows
  end

  def accreditation_dates_row(start_date, end_date)
    has_end_date = end_date.present?
    end_date_text = has_end_date ? end_date.to_fs(:govuk) : "Not entered"
    end_date_class = has_end_date ? "govuk-summary-list__value" : "govuk-summary-list__value govuk-hint"

    dates_html = tag.dl(class: "govuk-summary-list") do
      safe_join([
        tag.div(class: "govuk-summary-list__row") do
          tag.dt("Starts on", class: "govuk-summary-list__key") +
          tag.dd(start_date&.to_fs(:govuk), class: "govuk-summary-list__value")
        end,
        tag.div(class: "govuk-summary-list__row") do
          tag.dt("Ends on", class: "govuk-summary-list__key") +
          tag.dd(end_date_text, class: end_date_class)
        end
      ])
    end

    { key: { text: "Accreditation dates" },
      value: { text: dates_html } }
  end

  def accreditation_summary_cards(accreditations, provider, include_actions: true)
    return [] if accreditations.empty?

    accreditations.map do |accreditation|
      imported_data = provider.seed_data_notes.dig("row_imported", "accreditation") if provider.seed_data_notes.dig(
        "saved_as", "accreditation_id"
      ) == accreditation.id

      card = {
        title: "Accreditation #{accreditation.number}",
        rows: accreditation_rows(accreditation),
        imported_data: imported_data
      }

      if include_actions
        card[:actions] = [
          { text: "Change", href: edit_accreditation_path(accreditation, provider_id: provider.id) },
          { text: "Delete", href: accreditation_delete_path(accreditation, provider_id: provider.id) }
        ]
      end

      card
    end
  end
end
