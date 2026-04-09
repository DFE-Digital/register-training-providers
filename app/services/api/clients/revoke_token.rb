module Api
  module Clients
    class RevokeToken
      include ServicePattern

      def initialize(api_client:)
        @api_client = api_client
      end

      def call
        api_client.current_authentication_token.revoke!
      end

    private

      attr_reader :api_client
    end
  end
end
