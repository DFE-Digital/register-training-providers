module PartnershipHelper
  def partnership_summary_cards(partnerships, provider, include_actions: true)
    return [] if partnerships.empty?

    partnerships.map do |partnership|
      change_paths = if include_actions && policy(partnership).update?
                       partnership_card_change_paths(partnership, provider)
                     else
                       {}
                     end

      card = {
        title: link_to(partnership.other_partner(provider).operating_name.to_s,
                       provider_partnerships_path(partnership.other_partner(provider))),
        rows: partnership_rows(partnership,
                               change_paths: change_paths,
                               provider_accredited: provider.accredited?,
                               partnership_types: partnership_types_for(partnership),
                               show_status: true,
                               enter_end_date: true)
      }

      if include_actions && policy(partnership).update?
        card[:actions] = []
        if partnership.can_be_ended?
          card[:actions] << { text: "End partnership",
                              href: provider_partnership_end_path(partnership, provider_id: provider.id) }
        end
        card[:actions] << { text: "Delete",
                            href: provider_partnership_delete_path(partnership, provider_id: provider.id) }
      end

      card
    end
  end

  def partnership_card_change_paths(partnership, provider)
    {
      types: partnership_edit_step_path(provider, partnership, "types"),
      start_date: partnership_edit_step_path(provider, partnership, "start-date"),
      end_date: partnership_edit_step_path(provider, partnership, "end-date-question"),
      academic_years: partnership_edit_step_path(provider, partnership, "academic-years")
    }
  end

  def partnership_edit_step_path(provider, partnership, step)
    provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id,
                                        step: step, return_to_review: "true")
  end

  def partnership_rows(partnership, change_paths: {}, provider_accredited: nil, partnership_types: nil,
                       show_status: false, enter_end_date: false)
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
    rows << partnership_end_row(partnership.duration, change_paths[:end_date], enter_end_date:)

    if show_status
      tag_details = partnership.status_tag
      rows << { key: { text: "Status" },
                value: { text: govuk_tag(text: tag_details[:text], colour: tag_details[:colour]) } }
    end

    years_row = academic_years_row(partnership.academic_years, false, false)
    if change_paths[:academic_years].present?
      years_row[:actions] = [{ href: change_paths[:academic_years], visually_hidden_text: "academic years" }]
    end
    rows << years_row

    rows
  end

  def historic_partnership_rows(partnerships, provider)
    partnerships.map do |partnership|
      [
        { text: partnership.other_partner(provider).operating_name.to_s },
        { text: partnership_types_list(partnership_types_for(partnership)) },
        { text: partnership.duration.begin&.to_fs(:govuk).to_s },
        { text: partnership_end_date_text(partnership.duration) }
      ]
    end
  end

  def partnership_types_list(types)
    return tag.span("Not entered", class: "govuk-hint") if types.empty?

    tag.ul(class: "govuk-list govuk-list--bullet") do
      safe_join(types.map { |type| tag.li(PartnershipTypeEnum.label_for(type)) })
    end
  end

  def partnership_types_for(partnership)
    partnership.partnership_types.reject(&:discarded?).map(&:partnership_type)
  end

  def partnership_types_row(partnership_types, change_path)
    value = partnership_types_list(Array(partnership_types))

    row = { key: { text: "Partnership types" }, value: { text: value } }
    row[:actions] = [{ href: change_path, visually_hidden_text: "partnership types" }] if change_path.present?
    row
  end

  def partnership_start_row(duration, change_path)
    row = { key: { text: "Starts" }, value: { text: duration.begin&.to_fs(:govuk) } }
    row[:actions] = [{ href: change_path, visually_hidden_text: "partnership start date" }] if change_path.present?
    row
  end

  def partnership_end_date_text(duration)
    duration.end.is_a?(Date) ? duration.end.to_fs(:govuk) : "No end date"
  end

  def partnership_end_row(duration, change_path, enter_end_date: false)
    has_end_date = duration.end.is_a?(Date)

    row = {
      key: { text: "Ends" },
      value: {
        text: partnership_end_date_text(duration),
        classes: has_end_date ? nil : "govuk-hint"
      }
    }

    if change_path.present?
      action = { href: change_path, visually_hidden_text: "partnership end date" }
      action[:text] = "Enter end date" if enter_end_date && !has_end_date
      row[:actions] = [action]
    end

    row
  end
end
