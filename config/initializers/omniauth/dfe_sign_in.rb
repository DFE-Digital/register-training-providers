if ENV["SIGN_IN_METHOD"] == "dfe-sign-in"

  OmniAuth.config.logger = Rails.logger

  issuer_uri = URI.parse(ENV.fetch("DFE_SIGN_IN_ISSUER", nil))
  issuer_uri_with_port = "#{issuer_uri}:#{issuer_uri.port}" if issuer_uri.present?

  SETUP_PROC = lambda do |env|
    request = Rack::Request.new(env)

    redirect_uri = URI.join(request.base_url, "/auth/dfe/callback")

    env["omniauth.strategy"].options.client_options = {
      port: issuer_uri.port,
      scheme: issuer_uri.scheme,
      host: issuer_uri.host,
      identifier: ENV.fetch("DFE_SIGN_IN_IDENTIFIER", nil),
      secret: ENV.fetch("DFE_SIGN_IN_SECRET", nil),
      redirect_uri: redirect_uri,
    }
  end

  Rails.application.config.middleware.use(OmniAuth::Builder) do
    provider(:openid_connect, {
      name: :dfe,
      discovery: true,
      scope: %i[email profile],
      response_type: :code,
      path_prefix: "/auth",
      callback_path: "/auth/dfe/callback",
      issuer: issuer_uri_with_port,
      setup: SETUP_PROC,
    })
  end
end
