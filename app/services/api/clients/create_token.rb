module Api
  module Clients
    class CreateToken
      include ServicePattern

      def initialize(client_name:, created_by_email:, expires_at: nil)
        @client_name = client_name&.strip
        @created_by_email = created_by_email&.strip
        @expires_at = expires_at&.strip
      end

      def call
        AuthenticationToken.create_with_random_token(
          api_client: api_client,
          created_by: created_by,
          expires_at: parsed_expiry
        )
      end

    private

      attr_reader :client_name, :created_by_email, :expires_at

      def api_client
        @api_client ||= ApiClient.kept.find_or_create_by!(name: client_name)
      end

      def created_by
        @created_by ||= User.kept.find_by!(email: created_by_email)
      end

      def parsed_expiry
        return nil if expires_at.blank?

        @parsed_expiry ||= begin
          Date.parse(expires_at)
        rescue ArgumentError
          raise ArgumentError, "Invalid expiry date: #{expires_at.inspect}"
        end
      end
    end
  end
end
