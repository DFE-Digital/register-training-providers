module ApiClients
  class ConfirmationsController < ApplicationController
    def show
      @api_client = ApiClient.find(params[:api_client_id])
    end
  end
end
