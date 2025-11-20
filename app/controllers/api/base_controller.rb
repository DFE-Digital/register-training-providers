module Api
  class BaseController < ActionController::API
    include Api::ErrorResponse

    before_action :check_feature_flag!, :authenticate!, :update_last_used_at_on_token!

    def check_feature_flag!
      return if Env.feature_flag_api?

      render_not_found
    end

    def authenticate!
      return if valid_authentication_token?

      render(status: :unauthorized, json: { error: "Unauthorized" })
    end

    def current_api_client
      @current_api_client ||= auth_token&.api_client
    end

    def audit_user
      current_api_client
    end

    def current_user
      current_api_client
    end

    def render_not_found(message: "Not found")
      render(**not_found_response(message:))
    end

    def current_version
      params[:api_version]
    end

    def update_last_used_at_on_token!
      return unless valid_authentication_token?

      auth_token.update_last_used_at!
    end

  private

    alias_method :version, :current_version

    def valid_authentication_token?
      auth_token&.active? && current_api_client&.kept?
    end

    def auth_token
      return if bearer_token.blank?

      @auth_token ||= AuthenticationToken.authenticate(bearer_token)
    end

    def bearer_token
      request.authorization&.delete_prefix("Bearer ")&.strip
    end
  end
end
