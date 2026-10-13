module Providers
  class AccreditationHistoriesController < ApplicationController
    helper_method :provider

    def show
      @provider = Provider.kept.find(params[:provider_id])
      authorize @provider, :show?
    end

  private

    attr_reader :provider
  end
end
