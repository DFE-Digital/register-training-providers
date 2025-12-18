module ProviderHelper
  # Base rows for displaying provider details in summary cards/lists.
  # Used by: provider index cards, provider show page, activity log.
  def provider_summary_card_rows(provider)
    [
      { key: { text: "Provider type" }, value: { text: provider.provider_type_label } },
      { key: { text: "Accreditation type" }, value: { text: provider.accreditation_status_label } },
      { key: { text: "Operating name" }, value: { text: provider.operating_name } },
      { key: { text: "Legal name" }, value: optional_value(provider.legal_name) },
      { key: { text: "UK provider reference number (UKPRN)" }, value: { text: provider.ukprn } },
      { key: { text: "Unique reference number (URN)" }, value: optional_value(provider.urn) },
      { key: { text: "Provider code" }, value: { text: provider.code } },
    ]
  end

  # Summary cards for the providers index page.
  def provider_summary_cards(providers)
    providers.map do |provider|
      tag = [" ", govuk_tag(text: "Archived", classes: "govuk-!-margin-left-1")] if provider.archived?
      path_options = params[:debug] == "true" ? { debug: "true" } : {}

      {
        title: safe_join([govuk_link_to(provider.operating_name, provider_path(provider, path_options)), tag]),
        rows: provider_summary_card_rows(provider)
      }
    end
  end

  # Rows for form check-your-answers pages with configurable change paths.
  def provider_rows(provider, change_path, change_provider_type_path: nil, change_provider_details_path: nil)
    provider_details_change_path = change_provider_details_path || change_path

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

    # Add edit actions to editable fields (skip Provider type and Accreditation type)
    editable_fields = {
      "Operating name" => "operating name",
      "Legal name" => "legal name",
      "UK provider reference number (UKPRN)" => "UK provider reference number (UKPRN)",
      "Unique reference number (URN)" => "unique reference number (URN)",
      "Provider code" => "provider code"
    }

    rows.each do |row|
      key_text = row[:key][:text]
      if editable_fields.key?(key_text)
        row[:actions] = [{ href: edit_provider_path(provider), visually_hidden_text: editable_fields[key_text] }]
      end
    end

    rows
  end
end
