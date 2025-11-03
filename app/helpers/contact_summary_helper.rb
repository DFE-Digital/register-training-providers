module ContactSummaryHelper
  def contact_summary_cards(contacts, provider, include_actions: true)
    return [] if contacts.empty?

    contacts.map do |contact|
      card = {
        title: "#{contact.first_name} #{contact.last_name}",
        rows: contact_rows(contact)
      }

      if include_actions && !provider.archived?
        card[:actions] = [
          { text: "Change", href: edit_provider_contact_path(contact, provider_id: provider.id) },
          { text: "Delete", href: "#" },
        ]
      end

      card
    end
  end

  def contact_rows(contact)
    [
      { key: { text: "First name" },
        value: { text: contact.first_name }, },
      { key: { text: "Last name" },
        value: { text: contact.last_name },  },
      { key: { text: "Email address" },
        value: { text: contact.email }, },
      { key: { text: "Telephone" },
        value: { text: contact.telephone_number }, },
    ]
  end

  def contact_form_rows(form, change_path = nil)
    contact_attributes = [
      :first_name,
      :last_name,
      :email,
      :telephone_number,
    ]

    contact_attributes.map do |attribute|
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
