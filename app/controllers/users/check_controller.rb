class Users::CheckController < CheckController
  def generate_rows
    [
      { key: { text: "First name" }, value: { text: model.first_name } },
      { key: { text: "Last name" }, value: { text: model.last_name } },
      { key: { text: "Email address" }, value: { text: model.email } },
    ]
  end
end
