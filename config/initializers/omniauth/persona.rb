if ENV["SIGN_IN_METHOD"] == "persona"
  Rails.application.config.middleware.use(OmniAuth::Builder) do
    provider(
      :developer,
      fields: %i[uid email first_name last_name],
      uid_field: :uid
    )
  end
end
