module AddressSummaryHelper
  def address_rows(address)
    address_parts = [
      address.address_line_1,
      address.address_line_2,
      address.address_line_3,
      address.town_or_city,
      address.county,
      address.postcode
    ].compact.compact_blank

    address_html = content_tag :p, class: "govuk-body" do
      safe_join(address_parts, tag.br)
    end

    [
      {
        key: { text: "Address" },
        value: { text: address_html }
      },
      location_row(address)
    ].compact
  end

  def location_row(address)
    return nil unless address.latitude.present? && address.longitude.present?

    location_rows = [
      { key: { text: "Latitude" }, value: { text: address.latitude } },
      { key: { text: "Longitude" }, value: { text: address.longitude } }
    ]

    {
      key: { text: "Location" },
      value: { text: govuk_summary_list(rows: location_rows) }
    }
  end

  def address_form_rows(form, change_path = nil)
    address_attributes = [
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :town_or_city,
      :county,
      :postcode
    ]

    address_attributes.map do |attribute|
      key_label = attribute.to_s.humanize
      hidden_label = key_label.downcase

      row = {
        key: { text: key_label },
        value: optional_value(form.public_send(attribute))
      }

      if change_path
        row[:actions] = [{ href: change_path, visually_hidden_text: hidden_label }]
      end

      row
    end
  end

  def address_summary_cards(addresses, provider, include_actions: true)
    return [] if addresses.empty?

    addresses.map do |address|
      card = {
        title: "#{address.town_or_city}, #{address.postcode}",
        rows: address_rows(address)
      }

      if include_actions && !provider.archived?
        card[:actions] = [
          { text: "Change", href: edit_provider_address_path(address, provider_id: provider.id) },
          { text: "Delete", href: provider_address_delete_path(address, provider_id: provider.id) },
        ]
      end

      card
    end
  end
end
