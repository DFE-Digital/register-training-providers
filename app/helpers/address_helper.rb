module AddressHelper
  def address_summary_cards(addresses, provider, include_actions: true)
    return [] if addresses.empty?

    addresses.map do |address|
      all_rows = address_basic_row(address)

      if show_location_section?(address)
        all_rows << location_row_with_coords(address)
      end

      card = {
        title: "#{address.town_or_city}, #{address.postcode}",
        rows: all_rows
      }

      if include_actions && !provider.archived?
        card[:actions] = [
          { text: "Change",
            href: provider_edit_address_path(address, provider_id: provider.id),
            visually_hidden_text: card[:title] },
          { text: "Delete",
            href: provider_address_delete_path(address, provider_id: provider.id),
            visually_hidden_text: card[:title] },
        ]
      end

      card
    end
  end

  def address_basic_row(address)
    address_parts = [
      address.address_line_1,
      address.address_line_2,
      address.address_line_3,
      address.town_or_city,
      address.county,
      address.postcode
    ].compact.compact_blank

    address_html = safe_join(address_parts, tag.br)

    [{
      key: { text: "Address" },
      value: { text: address_html }
    }]
  end

  def address_rows(address, change_path = nil)
    address_row = address_basic_row(address).first

    if change_path
      address_row[:actions] = [{ href: change_path, visually_hidden_text: "address" }]
    end

    [address_row].compact
  end

  def location_rows(address)
    return [] unless address.respond_to?(:latitude) && address.respond_to?(:longitude)
    return [] unless address.latitude.present? && address.longitude.present?

    [
      { key: { text: "Latitude" }, value: { text: address.latitude } },
      { key: { text: "Longitude" }, value: { text: address.longitude } }
    ]
  end

  def show_location_section?(address)
    address.respond_to?(:latitude) &&
      address.respond_to?(:longitude) &&
      address.latitude.present? &&
      address.longitude.present?
  end

  def location_row_with_coords(address)
    location_html = tag.dl(class: "govuk-summary-list") do
      safe_join([
        tag.div(class: "govuk-summary-list__row") do
          tag.dt("Latitude", class: "govuk-summary-list__key") +
          tag.dd(address.latitude.to_s, class: "govuk-summary-list__value")
        end,
        tag.div(class: "govuk-summary-list__row") do
          tag.dt("Longitude", class: "govuk-summary-list__key") +
          tag.dd(address.longitude.to_s, class: "govuk-summary-list__value")
        end
      ])
    end

    {
      key: { text: "Location" },
      value: { text: location_html }
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
end
