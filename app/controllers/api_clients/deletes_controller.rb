class ApiClients::DeletesController < CheckController
  def show
    @api_client = ApiClient.find(params[:api_client_id])
  end

  def destroy
    @api_client = ApiClient.find(params[:api_client_id])
    @api_client.discard!
    redirect_to(api_clients_path, flash: { success: "API client deleted" })
  end
end
