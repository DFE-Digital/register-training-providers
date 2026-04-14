module ApiClients
  class ConfirmationsController < ApplicationController
    before_action :redirect_if_current_active_token

    def show
      authorize api_client
      @token = Api::Clients::CreateToken.call(client_name: api_client.name, created_by_email: current_user.email,
                                              expires_at: api_client_form.expires_at.to_s).token
    end

  private

    def api_client
      @api_client ||= ApiClient.find(params[:api_client_id])
    end

    def api_client_form
      current_user.load_temporary(ApiClientForm, purpose: :check_your_answers)
    end

    def redirect_if_current_active_token
      redirect_to api_clients_path if api_client.current_authentication_token.present?
    end
  end
end
