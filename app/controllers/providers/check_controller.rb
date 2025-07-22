class Providers::CheckController < CheckController
  def generate_rows
    [

      { key: { text: "Provider type" },
        value: { text: provider_type_text },
        actions: [{ href: new_provider_type_path(goto: "confirm"), visually_hidden_text: "provider type" }] },
      { key: { text: "Operating name" },
        value: { text: model.operating_name },
        actions: [{ href: change_path, visually_hidden_text: "operating name" }] },
      { key: { text: "Legal name" },
        value: optional_value(model.legal_name),
        actions: [{ href: change_path, visually_hidden_text: "legal name" }] },
      { key: { text: "UK provider reference number (UKPRN)" },
        value: { text: model.ukprn },
        actions: [{ href: change_path, visually_hidden_text: "UK provider reference number (UKPRN)" }] },
      { key: { text: "Unique reference number (URN)" },
        value: optional_value(model.urn),
        actions: [{ href: change_path, visually_hidden_text: "unique reference number (URN)" }] },
      { key: { text: "Provider code" },
        value: { text: model.code },
        actions: [{ href: change_path, visually_hidden_text: "provider code" }] },
    ]
  end

  def back_path
    new_provider_details_path
  end

  def change_path
    new_provider_details_path(goto: "confirm")
  end

  def purpose
    :create_provider
  end

private

  def not_entered
    { text: "Not entered", classes: "govuk-hint" }
  end

  def optional_value(value)
    value.present? ? { text: value } : not_entered
  end

  def provider_type_text
    I18n.t("forms.providers.provider_type.provider_type.#{model.provider_type}")
  end
end
