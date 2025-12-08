module DebuggerParamHelper
  def debug_mode?
    params["debug"] == "true"
  end

  def debug_provider(provider)
    return unless debug_mode? && provider.seed_data_notes.present?

    content_tag(:div) do
      concat(content_tag(:h3, "Seed data", class: "govuk-heading-m"))

      if provider.seed_data_notes["errors"].present?
        concat(content_tag(:h4, "Data errors", class: "govuk-heading-s"))
        concat(
          govuk_table(
            rows: [["Field", { text: "Error" }]] +
                  provider.seed_data_notes["errors"].map do |field, field_errors|
                    [field, { text: safe_join(field_errors.map(&:to_s), tag.br) }]
                  end,
            first_cell_is_header: true
          )
        )
      end

      if provider.seed_data_notes.dig("row_imported", "provider").present?
        concat(content_tag(:h4, "Imported data", class: "govuk-heading-s"))

        concat(
          govuk_table(
            rows: [["Field", { text: "Value" }]] +
                  I18n.t("imported_data.fields.provider").filter_map do |field, label|
                    value = if provider.seed_data_notes["row_imported"]["provider"][field.to_s].presence
                              { text: provider.seed_data_notes["row_imported"]["provider"][field.to_s] }
                            else
                              not_entered
                            end
                    [label, value]
                  end,
            first_cell_is_header: true
          )
        )
      end
    end
  end

  def debug_accreditation(provider, accreditation_number, summary_list)
    accreditation = provider.seed_data_notes.dig("row_imported", "accreditation")
    return unless debug_mode? && accreditation.present? && accreditation["number"] == accreditation_number

    summary_list.with_row do |row|
      row.with_key(text: "Imported data")

      debug_rows = I18n.t("imported_data.fields.accreditation").filter_map do |field, label|
        value = accreditation[field.to_s].present? ? { text: accreditation[field.to_s] } : not_entered
        { key: { text: label }, value: value }
      end

      row.with_value(text: govuk_summary_list(rows: debug_rows))
    end
  end
end
