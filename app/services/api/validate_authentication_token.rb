module Api
  class ValidateAuthenticationToken
    include ServicePattern

    attr_reader :auth_token

    def initialize(auth_token:)
      @auth_token = auth_token
      super()
    end

    def call
      auth_token&.active? && api_client&.kept?
    end

  private

    def api_client
      @api_client ||= auth_token&.api_client
    end
  end
end
