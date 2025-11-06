module Providers
  module Addresses
    class SelectController < ApplicationController
      include AddressSelector

      def new
        return unless load_selection_form

        @presenter = build_select_presenter(@results, @find_form, nil)
      end

      def create
        perform_address_selection
      end

    private

      def find_purpose
        :"find_address_#{provider.id}"
      end

      def search_results_purpose
        :"address_search_results_#{provider.id}"
      end

      def find_path
        provider_new_find_path(provider)
      end

      def confirm_path
        provider_new_address_confirm_path(provider)
      end

      def address_form_purpose
        :create_address
      end

      def save_selected_address(address_form)
        address_form.save_as_temporary!(created_by: current_user, purpose: :create_address)
      end

      def build_select_presenter(results, find_form, error)
        AddressJourney::SelectPresenter.new(
          results:,
          find_form:,
          provider:,
          error:
        )
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
