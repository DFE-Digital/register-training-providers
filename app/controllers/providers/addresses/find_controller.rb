module Providers
  module Addresses
    class FindController < ApplicationController
      include AddressFinder

      def new
        load_find_form
        @presenter = build_find_presenter(@form)
      end

      def create
        perform_address_search
      end

    private

      def find_purpose
        :"find_address_#{provider.id}"
      end

      def search_results_purpose
        :"address_search_results_#{provider.id}"
      end

      def select_path
        provider_new_select_path(provider)
      end

      def build_find_presenter(form)
        AddressJourney::FindPresenter.new(form:, provider:)
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
