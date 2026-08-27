module ProviderHelper
  # Base rows for displaying provider details in summary cards/lists.
  # Used by: provider index cards, provider show page.
  def provider_summary_card_rows(provider, hide_provider_code: false, hide_ukprn: false, hide_urn: false,
                                 use_details_for_academic_years_row: false, hide_onboarded_at: false,
                                 hide_first_active_at: false, hide_inactive_periods: false)
    summary_card_rows = [
      { key: { text: "RoTP Id" }, value: { text: provider.rotp_id } },
      { key: { text: "Provider type" }, value: { text: provider.provider_type_label } },
      { key: { text: "Accreditation status" }, value: { text: provider.accreditation_status_label } },
      { key: { text: "Operating name" }, value: { text: provider.operating_name } },
      { key: { text: "Legal name" }, value: optional_value(provider.legal_name) },
    ]

    summary_card_rows += [{ key: { text: "UK provider reference number (UKPRN)" },
                            value: { text: provider.ukprn } }] unless hide_ukprn
    summary_card_rows += [{ key: { text: "Unique reference number (URN)" },
                            value: optional_value(provider.urn) }] unless hide_urn
    summary_card_rows += [{ key: { text: "Provider code" },
                            value: { text: provider.code } }] unless hide_provider_code
    summary_card_rows += [{ key: { text: "Onboard at" },
                            value: {
                              text: provider.onboarded_at.to_fs(:govuk)
                            } }] unless hide_onboarded_at
    summary_card_rows += [{ key: { text: "First active at" },
                            value: {
                              text: provider.first_active_at.to_fs(:govuk)
                            } }] unless hide_first_active_at
    summary_card_rows += [academic_years_row(provider.active_academic_years.order(duration: :desc),
                                             use_details_for_academic_years_row, true)]

    unless hide_inactive_periods
      summary_card_rows += [{ key: { text: "Inactive periods" },
                              value: { text: inactive_periods_html(provider.inactive_periods) } }]
    end

    summary_card_rows
  end

  # Summary cards for the providers index page.
  def provider_summary_cards(providers)
    providers.map do |provider|
      path_options = params[:debug] == "true" ? { debug: "true" } : {}

      archived_tag =
        if provider.archived?
          govuk_tag(text: "Archived", classes: "govuk-!-margin-left-1")
        elsif provider.inactive?
          govuk_tag(text: "Inactive", colour: "yellow", classes: "govuk-!-margin-left-1")
        end

      provider_meta =
        if provider.code.present? || provider.ukprn.present? || provider.urn.present?
          tag.p(class: "govuk-hint govuk-!-margin-top-1 govuk-!-margin-bottom-0") do
            safe_join(
              [
                (safe_join([tag.b("Provider code:"), " #{provider.code}"]) if provider.code.present?),
                (safe_join([tag.b(tag.abbr("UKPRN", title: "UK provider reference number")),
                            ": #{provider.ukprn}"]) if provider.ukprn.present?),
                (safe_join([tag.b(tag.abbr("URN", title: "unique reference number")),
                            ": #{provider.urn}"]) if provider.urn.present?)
              ].compact,
              " "
            )
          end
        end

      title_parts = [
        govuk_link_to(provider.operating_name, provider_path(provider, path_options)),
        archived_tag,
        provider_meta
      ].compact

      {
        title: safe_join(title_parts, " "),
        rows: provider_summary_card_rows(
          provider,
          hide_provider_code: true,
          hide_ukprn: true,
          hide_urn: true,
          use_details_for_academic_years_row: true,
          hide_inactive_periods: true,
          hide_onboarded_at: true,
          hide_first_active_at: true
        )
      }
    end
  end

  # Rows for form check-your-answers pages with configurable change paths.
  def provider_rows(provider, change_path,
                    change_provider_type_path: nil,
                    change_provider_details_path: nil,
                    change_provider_onboarding_path: nil,
                    change_provider_first_become_active_path: nil)
    provider_details_change_path = change_provider_details_path || change_path

    onboarded_at_row = if change_provider_onboarding_path
                         [{
                           key: { text: "Onboard at" },
                           value: { text: provider.onboarded_at.to_fs(:govuk) },
                           actions: [{ href: change_provider_onboarding_path, visually_hidden_text: "onboarded date" }]
                         }]
                       else
                         []
                       end

    first_active_at_row = if change_provider_first_become_active_path
                            [{
                              key: { text: "First active at" },
                              value: { text: provider.first_active_at.to_fs(:govuk) },
                              actions: [{ href: change_provider_first_become_active_path,
                                          visually_hidden_text: "first active date" }]
                            }]
                          else
                            []
                          end

    provider_type_row = if change_provider_type_path
                          [{
                            key: { text: "Provider type" },
                            value: { text: provider.provider_type_label },
                            actions: [{ href: change_provider_type_path, visually_hidden_text: "provider type" }]
                          }]
                        else
                          []
                        end

    [
      *onboarded_at_row,
      *first_active_at_row,
      *provider_type_row,
      { key: { text: "Operating name" },
        value: { text: provider.operating_name },
        actions: [{ href: provider_details_change_path, visually_hidden_text: "operating name" }] },
      { key: { text: "Legal name" },
        value: optional_value(provider.legal_name),
        actions: [{ href: provider_details_change_path, visually_hidden_text: "legal name" }] },
      { key: { text: "UK provider reference number (UKPRN)" },
        value: { text: provider.ukprn },
        actions: [{ href: provider_details_change_path,
                    visually_hidden_text: "UK provider reference number (UKPRN)" }] },
      { key: { text: "Unique reference number (URN)" },
        value: optional_value(provider.urn),
        actions: [{ href: provider_details_change_path, visually_hidden_text: "unique reference number (URN)" }] },
      { key: { text: "Provider code" },
        value: { text: provider.code },
        actions: [{ href: provider_details_change_path, visually_hidden_text: "provider code" }] },
    ]
  end

  # Provider show page with edit actions (unless archived).
  def provider_details_rows(provider)
    rows = provider_summary_card_rows(provider)

    return rows if provider.archived?

    # Add edit actions to editable fields (skip Provider type and Accreditation status)
    editable_fields = {
      "Operating name" => { visually_hidden_text: "operating name", href: edit_provider_path(provider) },
      "Legal name" => { visually_hidden_text: "legal name", href: edit_provider_path(provider) },
      "UK provider reference number (UKPRN)" => { visually_hidden_text: "UK provider reference number (UKPRN)",
                                                  href: edit_provider_path(provider) },
      "Unique reference number (URN)" => { visually_hidden_text: "unique reference number (URN)",
                                           href: edit_provider_path(provider) },
      "Provider code" => { visually_hidden_text: "provider code",
                           href: provider_change_step_path(
                             provider_id: provider.id,
                             field: "code",
                             step: "effective-academic-year"
                           ) },
    }.with_indifferent_access

    rows.each do |row|
      key_text = row[:key][:text]
      next unless editable_fields.key?(key_text)

      row[:actions] =
        [{ href: editable_fields[key_text][:href],
           visually_hidden_text: editable_fields[key_text][:visually_hidden_text] }]
    end

    rows
  end

  def inactive_periods_html(inactive_periods)
    return content_tag(:p, "No inactive periods") if inactive_periods.empty?

    content_tag(:ul, class: "govuk-list govuk-list") do
      inactive_periods.map { |period|
        content_tag(:li, govuk_summary_list(rows: display_inactive_period(period)))
      }.join.html_safe
    end
  end

  def mark_as_inactive_rows(inactive_period)
    [
      {
        key: { text: "Inactive period start date" },
        value: { text: inactive_period["start_date"].to_date.strftime("%d %B %Y") },
        actions: [{ href: provider_mark_as_inactive_path, visually_hidden_text: "start date" }]
      },
      {
        key: { text: "Why did the provider become inactive" },
        value: { text: inactive_reasons_html(inactive_period["reasons_for_inactive"]) },
        actions: [{ href: provider_mark_as_inactive_reasons_path, visually_hidden_text: "reasons" }]
      },
    ]
  end

  def mark_as_active_rows(inactive_period)
    [
      {
        key: { text: "Inactive period end date" },
        value: { text: inactive_period["end_date"].to_date.to_fs(:govuk) },
        actions: [{ href: provider_mark_as_active_path, visually_hidden_text: "end date" }]
      },
    ]
  end

  def inactive_reasons_html(reasons)
    content_tag(:ul, class: "govuk-list govuk-list") do
      reasons.map { |reason|
        content_tag(:li, reason)
      }.join.html_safe
    end
  end

  def display_inactive_period(period)
    [
      { key: { text: "Starts on" },
        value: { text: display_date(period["start_date"]) } },
      { key: { text: "Ends on" },
        value: { text: display_date(period["end_date"]) } },
    ]
  end

  def display_date(date)
    return "Not entered" if date.blank?

    date.to_date.to_fs(:govuk)
  end
end
