module SummaryHelper
  def optional_value(value)
    value.present? ? { text: value } : not_entered
  end

  def not_entered
    { text: "Not entered", classes: "govuk-hint" }
  end

  def provider_summary_cards(providers)
    providers.map do |provider|
      tag = [" ", govuk_tag(text: "Archived", classes: "govuk-!-margin-left-1")] if provider.archived?

      {
        title: safe_join([govuk_link_to(provider.operating_name, provider_path(provider)),
                          tag]),
        rows: [

          { key: { text: "Provider type" },
            value: { text: provider.provider_type_label }, },
          { key: { text: "Accreditation type" },
            value: { text: provider.accreditation_status_label }, },
          { key: { text: "Operating name" },
            value: { text: provider.operating_name }, },
          { key: { text: "Legal name" },
            value: optional_value(provider.legal_name), },
          { key: { text: "UK provider reference number (UKPRN)" },
            value: { text: provider.ukprn }, },
          { key: { text: "Unique reference number (URN)" },
            value: optional_value(provider.urn), },
          { key: { text: "Provider code" },
            value: { text: provider.code }, },
        ]
      }
    end
  end

  def user_rows(user, change_path)
    [
      { key: { text: "First name" },
        value: { text: user.first_name },
        actions: [{ href: change_path, visually_hidden_text: "first name" }] },
      { key: { text: "Last name" },
        value: { text: user.last_name },
        actions: [{ href: change_path, visually_hidden_text: "last name" }] },
      { key: { text: "Email address" },
        value: { text: user.email },
        actions: [{ href: change_path, visually_hidden_text: "email address" }] },
    ]
  end

  def provider_rows(provider, change_path, change_provider_type_path: nil)
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
      *provider_type_row,
      { key: { text: "Operating name" },
        value: { text: provider.operating_name },
        actions: [{ href: change_path, visually_hidden_text: "operating name" }] },
      { key: { text: "Legal name" },
        value: optional_value(provider.legal_name),
        actions: [{ href: change_path, visually_hidden_text: "legal name" }] },
      { key: { text: "UK provider reference number (UKPRN)" },
        value: { text: provider.ukprn },
        actions: [{ href: change_path, visually_hidden_text: "UK provider reference number (UKPRN)" }] },
      { key: { text: "Unique reference number (URN)" },
        value: optional_value(provider.urn),
        actions: [{ href: change_path, visually_hidden_text: "unique reference number (URN)" }] },
      { key: { text: "Provider code" },
        value: { text: provider.code },
        actions: [{ href: change_path, visually_hidden_text: "provider code" }] },
    ]
  end

  def provider_details_rows(provider)
    rows = [
      { key: { text: "Provider type" }, value: { text: provider.provider_type_label } },
      { key: { text: "Accreditation type" }, value: { text: provider.accreditation_status_label } },
      { key: { text: "Operating name" },
        value: { text: provider.operating_name },
        actions: [{ href: edit_provider_path(provider), visually_hidden_text: "operating name" }] },
      { key: { text: "Legal name" },
        value: optional_value(provider.legal_name),
        actions: [{ href: edit_provider_path(provider), visually_hidden_text: "legal name" }] },
      { key: { text: "UK provider reference number (UKPRN)" },
        value: { text: provider.ukprn },
        actions: [{ href: edit_provider_path(provider),
                    visually_hidden_text: "UK provider reference number (UKPRN)" }] },
      { key: { text: "Unique reference number (URN)" },
        value: optional_value(provider.urn),
        actions: [{ href: edit_provider_path(provider), visually_hidden_text: "unique reference number (URN)" }] },
      { key: { text: "Provider code" },
        value: { text: provider.code },
        actions: [{ href: edit_provider_path(provider), visually_hidden_text: "provider code" }] },
    ]

    if provider.archived?
      rows.each { |row| row.delete(:actions) }
    end

    rows
  end
end
