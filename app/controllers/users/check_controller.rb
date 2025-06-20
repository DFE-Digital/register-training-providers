class Users::CheckController < CheckController
  def generate_rows
    [
      { key: { text: "First name" },
        value: { text: model.first_name },
        actions: [{ href: new_model_path, visually_hidden_text: "first name" }] },
      { key: { text: "Last name" },
        value: { text: model.last_name },
        actions: [{ href: new_model_path, visually_hidden_text: "last name" }] },
      { key: { text: "Email address" },
        value: { text: model.email },
        actions: [{ href: new_model_path, visually_hidden_text: "email address" }] },
    ]
  end
end
