module AccreditationHelper
  def accreditation_form_rows(accreditation_form, change_path = nil)
    return [] unless accreditation_form&.valid?

    change_path ||= new_provider_accreditation_path(goto: "confirm")

    [
      { key: { text: "Accredited provider number" },
        value: { text: accreditation_form.number },
        actions: [{ href: change_path, visually_hidden_text: "accredited provider number" }] },
      { key: { text: "Date accreditation starts" },
        value: { text: accreditation_form.start_date&.to_fs(:govuk) },
        actions: [{ href: change_path, visually_hidden_text: "date accreditation starts" }] },
      { key: { text: "Date accreditation ends" },
        value: if accreditation_form.end_date.present?
                 { text: accreditation_form.end_date.to_fs(:govuk) }
               else
                 not_entered
               end,
        actions: [{ href: change_path, visually_hidden_text: "date accreditation ends" }] }
    ]
  end

  def accreditation_rows(accreditation, change_path = nil)
    rows = [
      { key: { text: "Accreditation number" },
        value: { text: accreditation.number } },
      { key: { text: "Date accreditation starts" },
        value: { text: accreditation.start_date&.to_fs(:govuk) } },
      { key: { text: "Date accreditation ends" },
        value: if accreditation.end_date.present?
                 { text: accreditation.end_date.to_fs(:govuk) }
               else
                 not_entered
               end }
    ]

    if change_path
      rows.each_with_index do |row, index|
        visually_hidden_texts = ["accreditation number", "date accreditation starts", "date accreditation ends"]
        row[:actions] = [{ href: change_path, visually_hidden_text: visually_hidden_texts[index] }]
      end
    end

    rows
  end

  def accreditation_summary_cards(accreditations, provider, include_actions: true)
    return [] if accreditations.empty?

    accreditations.map do |accreditation|
      card = {
        title: "Accreditation #{accreditation.number}",
        number: accreditation.number,
        rows: accreditation_rows(accreditation)
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
