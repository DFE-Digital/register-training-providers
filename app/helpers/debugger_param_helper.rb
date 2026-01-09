module DebuggerParamHelper
  def debug_mode?
    params["debug"] == "true"
  end

  def address_import_new_journey?
    params["address_import_new_journey"] == "true"
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

  def debug_accreditation(imported_data, summary_list)
    debug_summary_list("accreditation", imported_data, summary_list)
  end

  def debug_address(imported_data, summary_list)
    debug_summary_list("address", imported_data, summary_list)
  end

  def debug_address_summary_card(provider)
    return unless debug_mode?

    imported_data = provider.seed_data_notes.dig("row_imported", "address")

    return if imported_data.blank?

    govuk_summary_card(title: "Imported data") do |card|
      rows = debug_rows("address", imported_data)

      card.with_summary_list(rows:)
    end
  end

  def debug_summary_list(imported_model_name, imported_data, summary_list)
    return unless debug_mode? && imported_data.present?

    summary_list.with_row do |row|
      row.with_key(text: "Imported data")

      rows = debug_rows(imported_model_name, imported_data)

      row.with_value(text: govuk_summary_list(rows:))
    end
  end

  def debug_rows(imported_model_name, imported_data)
    I18n.t("imported_data.fields.#{imported_model_name}").filter_map do |field, label|
      value = imported_data[field.to_s].present? ? { text: imported_data[field.to_s] } : not_entered
      { key: { text: label }, value: value }
    end
  end
end
