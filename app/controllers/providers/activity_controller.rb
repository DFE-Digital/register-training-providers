module Providers
  class ActivityController < ApplicationController
    include Pagy::Backend

    def index
      authorize provider, :show?
      audits = AuditsQuery.call(provider: provider)
      @pagy, @audits = pagy(audits, limit: 25)
      @provider = provider
    end

  private

    def provider
      @provider ||= policy_scope(Provider).find(params[:provider_id])
    end
  end
end

