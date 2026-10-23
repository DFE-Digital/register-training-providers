module Providers
  module Addresses
    class HistoricController < ApplicationController
      def index
        authorize provider, :show?

        @addresses = policy_scope(provider.addresses.historic)
      end

    private

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
