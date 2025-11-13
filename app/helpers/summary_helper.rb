module SummaryHelper
  def optional_value(value)
    value.present? ? { text: value } : not_entered
  end

  def not_entered
    { text: "Not entered", classes: "govuk-hint" }
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
end
