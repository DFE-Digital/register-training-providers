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
          { text: "Change", href: "#" },
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
        value: { text: contact.email_address }, },
      { key: { text: "Telephone" },
        value: { text: contact.telephone_number }, },
    ]
  end
end
