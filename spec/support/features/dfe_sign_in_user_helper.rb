module DfESignInUserHelper
  # Signs a request spec in as the given user through the real DfE Sign-in
  # callback. Lives here rather than in each spec so the callback dance (and the
  # mock auth setup it depends on) exists once.
  def sign_in_as(user)
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  def user_exists_in_dfe_sign_in(user:)
    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
      fake_dfe_sign_in_auth_hash(
        email: user.email,
        dfe_sign_in_uid: user.dfe_sign_in_uid,
        first_name: user.first_name,
        last_name: user.last_name,
      ),
    )
  end

private

  def fake_dfe_sign_in_auth_hash(email:, dfe_sign_in_uid:, first_name:, last_name:)
    {
      "provider" => "dfe",
      "uid" => dfe_sign_in_uid,
      "info" => {
        "name" => "#{first_name} #{last_name}",
        "email" => email,
        "nickname" => nil,
        "first_name" => first_name,
        "last_name" => last_name,
        "gender" => nil,
        "image" => nil,
        "phone" => nil,
        "urls" => { "website" => nil },
      },
      "credentials" => {
        "id_token" => "id_token",
        "token" => "DFE_SIGN_IN_TOKEN",
        "refresh_token" => nil,
        "expires_in" => 3600,
        "scope" => "email openid",
      },
      "extra" => {
        "raw_info" => {
          "email" => email,
          "sub" => dfe_sign_in_uid,
        },
      },
    }
  end
end

RSpec.configure do |config|
  # OmniAuth's mock strategy is global configuration rather than per-example
  # state, so an identity stubbed in one request example would leak into the
  # next. Reset it centrally instead of copying the same `after` hook into every
  # request spec that signs somebody in.
  config.after(:each, type: :request) { OmniAuth.config.mock_auth.clear }
end
