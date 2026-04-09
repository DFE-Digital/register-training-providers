module ApiClients
  class ConfirmationsController < ApplicationController
    def show
      @api_client = ApiClient.find(params[:api_client_id])
      authorize @api_client
    end
  end
end
