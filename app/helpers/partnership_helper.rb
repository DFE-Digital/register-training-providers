module PartnershipHelper
  def partnership_summary_cards(partnerships, provider, include_actions: true)
    return [] if partnerships.empty?

    partnerships.map do |partnership|
      card = {
        title: link_to(partnership.other_partner(provider).operating_name.to_s,
                       provider_partnerships_path(partnership.other_partner(provider))),
        rows: partnership_rows(partnership, change_paths: {}, provider_accredited: nil)
      }

      if include_actions && !provider.archived?
        card[:actions] = [
          { text: "Change",
            href: provider_edit_partnership_dates_path(partnership, provider_id: provider.id) },
          { text: "Delete", href: "#" },
        ]
      end

      card
    end
  end

  def partnership_rows(partnership, change_paths: {}, provider_accredited: nil)
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

    dates_row = partnership_dates_row(partnership.duration)
    if change_paths[:dates].present?
      dates_row[:actions] = [{ href: change_paths[:dates], visually_hidden_text: "partnership dates" }]
    end
    rows << dates_row

    years_row = academic_years_row(partnership.academic_cycles)
    if change_paths[:academic_cycles].present?
      years_row[:actions] = [{ href: change_paths[:academic_cycles], visually_hidden_text: "academic years" }]
    end
    rows << years_row

    rows
  end

  def partnership_dates_row(duration)
    end_date = duration.end
    has_end_date = end_date.present? && end_date.is_a?(Date)
    end_date_text = has_end_date ? end_date.to_fs(:govuk) : "Not entered"
    end_date_class = has_end_date ? "govuk-summary-list__value" : "govuk-summary-list__value govuk-hint"

    dates_html = tag.dl(class: "govuk-summary-list govuk-summary-list--no-border") do
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

  def academic_years_row(academic_cycles)
    academic_cycles_html = tag.ul(class: "govuk-list govuk-list--bullet") do
      academic_cycles.collect do |academic_cycle|
        concat tag.li(raw(display_academic_year(academic_cycle) + tag.br + tag.span(
          academic_year_helper_text(academic_cycle), class: "govuk-hint"
        )))
      end
    end

    { key: { text: "Academic years" },
      value: { text: academic_cycles_html } }
  end

  def display_academic_year(academic_cycle)
    academic_year_text = "#{academic_cycle.duration.begin.year} to #{academic_cycle.duration.end.year}"
    [:current, :last, :next].each do |label|
      academic_year_text += " - #{label}" if academic_cycle.send(:"#{label}?")
    end

    academic_year_text
  end

  def academic_year_helper_text(academic_cycle)
    "Starts on 1 August #{academic_cycle.duration.begin.year}, ends on 31 July #{academic_cycle.duration.end.year}"
  end
end
