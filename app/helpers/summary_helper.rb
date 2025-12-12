module SummaryHelper
  def optional_value(value)
    value.present? ? { text: value } : not_entered
  end

  def not_entered
    { text: "Not entered", classes: "govuk-hint" }
  end

  def user_rows(user, change_path = nil)
    rows = [
      { key: { text: "First name" }, value: { text: user.first_name } },
      { key: { text: "Last name" }, value: { text: user.last_name } },
      { key: { text: "Email address" }, value: { text: user.email } },
    ]

    if change_path
      rows[0][:actions] = [{ href: change_path, visually_hidden_text: "first name" }]
      rows[1][:actions] = [{ href: change_path, visually_hidden_text: "last name" }]
      rows[2][:actions] = [{ href: change_path, visually_hidden_text: "email address" }]
    end

    rows
  end
end
