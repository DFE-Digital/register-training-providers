module Providers
  module Addresses
    class SelectController < ApplicationController
      def new
        @search_results_form = current_user.load_temporary(
          ::Addresses::SearchResultsForm,
          purpose: search_results_purpose
        )

        if @search_results_form.nil?
          redirect_to new_provider_find_path(provider_id: provider.id)
          return
        end

        @find_form = current_user.load_temporary(
          ::Addresses::FindForm,
          purpose: find_purpose
        )

        @results = @search_results_form.results_array
      end

      def create
        @search_results_form = current_user.load_temporary(
          ::Addresses::SearchResultsForm,
          purpose: search_results_purpose
        )

        if @search_results_form.nil?
          redirect_to new_provider_find_path(provider_id: provider.id)
          return
        end

        @results = @search_results_form.results_array
        selected_index = selection_params[:selected_address_index].to_i

        if selected_index.negative? || selected_index >= @results.size
          @error = "Please select an address"
          render :new
          return
        end

        selected_address = @results[selected_index]
        address_form = AddressForm.from_os_address(selected_address.symbolize_keys)
        address_form.provider_id = provider.id

        if address_form.valid?
          address_form.save_as_temporary!(
            created_by: current_user,
            purpose: :create_address
          )

          current_user.clear_temporary(::Addresses::FindForm, purpose: find_purpose)
          current_user.clear_temporary(::Addresses::SearchResultsForm, purpose: search_results_purpose)

          redirect_to new_provider_address_confirm_path(provider_id: provider.id)
        else
          @error = "There was a problem with the selected address"
          render :new
        end
      end

    private

      def selection_params
        params.expect(select: [:selected_address_index])
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end

      def find_purpose
        :"find_address_#{provider.id}"
      end

      def search_results_purpose
        :"address_search_results_#{provider.id}"
      end
    end
  end
end
