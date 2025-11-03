module Providers
  module Setup
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
          :find_address_create_provider
        end

        def search_results_purpose
          :address_search_results_create_provider
        end

        def select_path
          providers_setup_addresses_select_path
        end

        def build_find_presenter(form)
          AddressJourney::Setup::FindPresenter.new(form:, provider:)
        end

        def provider
          @provider ||= current_user.load_temporary(Provider, purpose: :create_provider)
        end
      end
    end
  end
end
