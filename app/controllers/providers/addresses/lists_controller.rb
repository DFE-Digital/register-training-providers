module Providers
  module Addresses
    class ListsController < ApplicationController
      include Pagy::Backend

      def index
        authorize provider, :show?
        @addresses = policy_scope(provider.addresses)
      end

      def imported_data
        provider_query = Provider.kept.order_by_operating_name
        .where("seed_data_notes->'row_imported' ? 'address'")
        .where("(seed_data_notes->'saved_as'->>'address_id') IS NULL")

        @pagy, @providers = pagy(provider_query, limit: 50)
      end

    private

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
