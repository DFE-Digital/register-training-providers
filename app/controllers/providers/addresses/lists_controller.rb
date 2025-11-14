module Providers
  module Addresses
    class ListsController < ApplicationController
      def index
        authorize provider, :show?
        @addresses = policy_scope(provider.addresses)
      end

    private

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
