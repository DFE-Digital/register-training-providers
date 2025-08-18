module Providers
  class AccreditationsController < ApplicationController
    before_action :load_provider

    def index
      authorize @provider, :show?
      @accreditations = policy_scope(@provider.accreditations).order_by_start_date
    end

  private

    def load_provider
      @provider = policy_scope(Provider).find_by!(uuid: params[:provider_id])
    end
  end
end
