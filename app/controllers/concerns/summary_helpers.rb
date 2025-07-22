module SummaryHelpers
  extend ActiveSupport::Concern

private

  def optional_value(value)
    value.present? ? { text: value } : not_entered
  end

  def not_entered
    { text: "Not entered", classes: "govuk-hint" }
  end

  def provider_summary_cards(providers)
    providers.map do |provider|
      {
        title: provider.operating_name,
        rows: [

          { key: { text: "Provider type" },
            value: { text: provider.provider_type_label }, },
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
end
