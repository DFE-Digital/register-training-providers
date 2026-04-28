module SummaryHelper
  def optional_value(value)
    value.present? ? { text: value } : not_entered
  end

  def not_entered
    { text: "Not entered", classes: "govuk-hint" }
  end

  def boolean_value(value)
    value ? "Yes" : "No"
  end

  def user_rows(user, change_path = nil)
    rows = [
      { key: { text: "First name" }, value: { text: user.first_name } },
      { key: { text: "Last name" }, value: { text: user.last_name } },
      { key: { text: "Email address" }, value: { text: user.email } },
      { key: { text: "Is the account an API user?" }, value: { text: boolean_value(user.api_user) } },
    ]

    rows << { key: { text: "Is the account active?" }, value: { text: boolean_value(user.active) } } if user.persisted?

    if change_path
      if user.last_signed_in_at.nil?
        rows[0][:actions] = [{ href: change_path, visually_hidden_text: "first name" }]
        rows[1][:actions] = [{ href: change_path, visually_hidden_text: "last name" }]
        rows[2][:actions] = [{ href: change_path, visually_hidden_text: "email address" }]
      end
      rows[3][:actions] = [{ href: change_path, visually_hidden_text: "is the account an api user" }]
      rows[4][:actions] = [{ href: change_path, visually_hidden_text: "is the account active" }] if user.persisted?
    end

    rows
  end

  def api_client_rows(api_client, change_path = nil, method = nil)
    rows = [
      { key: { text: "Client name" }, value: { text: api_client.name } },
      { key: { text: "Expiry date" }, value: { text: api_client.expires_at.to_fs(:govuk) } },
    ]

    rows[0][:actions] = [{ href: change_path, visually_hidden_text: "client name" }] if change_path
    rows[1][:actions] = [{ href: change_path, visually_hidden_text: "expiry name" }] if change_path && method == :post

    rows
  end
end
