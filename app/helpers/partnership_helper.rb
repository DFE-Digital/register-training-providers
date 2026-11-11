module PartnershipHelper
  # Which side of the pair the current user is adding a partnership for.
  def partnership_partner_type(provider_accredited)
    provider_accredited ? "training_partner" : "accredited_provider"
  end

  def partnership_summary_cards(partnerships, provider, include_actions: true)
    return [] if partnerships.empty?

    partnerships.map do |partnership|
      card = {
        title: link_to(partnership.other_partner(provider).operating_name.to_s,
                       provider_partnerships_path(partnership.other_partner(provider))),
        rows: partnership_rows(partnership, change_paths: {}, provider_accredited: nil)
      }

      if include_actions && policy(partnership).update?
        card[:actions] = [
          { text: "Change",
            href: provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id,
                                                      step: "dates") },
          { text: "Delete",
            href: provider_partnership_delete_path(partnership, provider_id: provider.id) },
        ]
      end

      card
    end
  end

  def partnership_rows(partnership, change_paths: {}, provider_accredited: nil, partnership_types: nil)
    rows = []

    ap_row = { key: { text: "Accredited provider" },
               value: { text: partnership.accredited_provider.operating_name.to_s } }
    if provider_accredited == false && change_paths[:partner].present?
      ap_row[:actions] = [{ href: change_paths[:partner], visually_hidden_text: "accredited provider" }]
    end
    rows << ap_row

    tp_row = { key: { text: "Training partner" },
               value: { text: partnership.provider.operating_name.to_s } }
    if provider_accredited == true && change_paths[:partner].present?
      tp_row[:actions] = [{ href: change_paths[:partner], visually_hidden_text: "training partner" }]
    end
    rows << tp_row

    rows << partnership_types_row(partnership_types, change_paths[:types]) unless partnership_types.nil?

    dates_row = partnership_dates_row(partnership.duration)
    if change_paths[:dates].present?
      dates_row[:actions] = [{ href: change_paths[:dates], visually_hidden_text: "partnership dates" }]
    end
    rows << dates_row

    years_row = academic_years_row(partnership.academic_years, false, false)
    if change_paths[:academic_years].present?
      years_row[:actions] = [{ href: change_paths[:academic_years], visually_hidden_text: "academic years" }]
    end
    rows << years_row

    rows
  end

  def partnership_types_row(partnership_types, change_path)
    value = if partnership_types.present?
              tag.ul(class: "govuk-list govuk-list--bullet") do
                safe_join(partnership_types.map { |type| tag.li(PartnershipTypeEnum.label_for(type)) })
              end
            else
              tag.span("Not entered", class: "govuk-hint")
            end

    row = { key: { text: "Partnership types" }, value: { text: value } }
    row[:actions] = [{ href: change_path, visually_hidden_text: "partnership types" }] if change_path.present?
    row
  end

  def partnership_dates_row(duration)
    end_date = duration.end
    has_end_date = end_date.present? && end_date.is_a?(Date)
    end_date_text = has_end_date ? end_date.to_fs(:govuk) : "Not entered"
    end_date_class = has_end_date ? "govuk-summary-list__value" : "govuk-summary-list__value govuk-hint"

    dates_html = tag.dl(class: "govuk-summary-list") do
      safe_join([
        tag.div(class: "govuk-summary-list__row") do
          tag.dt("Starts on", class: "govuk-summary-list__key") +
          tag.dd(duration.begin&.to_fs(:govuk), class: "govuk-summary-list__value")
        end,
        tag.div(class: "govuk-summary-list__row govuk-summary-list__row--no-border") do
          tag.dt("Ends on", class: "govuk-summary-list__key") +
          tag.dd(end_date_text, class: end_date_class)
        end
      ])
    end

    { key: { text: "Partnership dates" },
      value: { text: dates_html } }
  end
end
