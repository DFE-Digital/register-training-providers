class ApiClients::RevokesController < CheckController
  def show
    @api_client = ApiClient.find(params[:api_client_id])
    authorize @api_client
  end

  def destroy
    api_client = ApiClient.find(params[:api_client_id])
    authorize api_client

    Api::Clients::RevokeToken.call(api_client:)
    redirect_to(api_clients_path, flash: { success: "API client revoked" })
  end
end
