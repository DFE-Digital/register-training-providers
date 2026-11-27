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
                                                      step: "start-date") },
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

    rows << partnership_start_row(partnership.duration, change_paths[:start_date])
    rows << partnership_end_row(partnership.duration, change_paths[:end_date])

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

  def partnership_start_row(duration, change_path)
    row = { key: { text: "Starts" }, value: { text: duration.begin&.to_fs(:govuk) } }
    row[:actions] = [{ href: change_path, visually_hidden_text: "partnership start date" }] if change_path.present?
    row
  end

  def partnership_end_row(duration, change_path)
    end_date = duration.end
    has_end_date = end_date.present? && end_date.is_a?(Date)

    row = {
      key: { text: "Ends" },
      value: {
        text: has_end_date ? end_date.to_fs(:govuk) : "No end date",
        classes: has_end_date ? nil : "govuk-hint"
      }
    }
    row[:actions] = [{ href: change_path, visually_hidden_text: "partnership end date" }] if change_path.present?
    row
  end
end
