module Providers
  module Addresses
    class FindController < ApplicationController
      def new
        current_user.clear_temporary(::Addresses::FindForm, purpose: find_purpose)
        current_user.clear_temporary(::Addresses::SearchResultsForm, purpose: search_results_purpose)
        current_user.clear_temporary(AddressForm, purpose: :create_address)
        
        @form = current_user.load_temporary(
          ::Addresses::FindForm,
          purpose: find_purpose
        )

        @form.provider_id = provider.id if @form.provider_id.blank?
      end

      def create
        @form = ::Addresses::FindForm.new(find_form_params)
        @form.provider_id = provider.id

        if @form.valid?
          results = OrdnanceSurvey::AddressLookupService.call(
            postcode: @form.postcode,
            building_name_or_number: @form.building_name_or_number
          )

          search_results_form = ::Addresses::SearchResultsForm.new
          search_results_form.results_array = results
          search_results_form.save_as_temporary!(
            created_by: current_user,
            purpose: search_results_purpose
          )

          @form.save_as_temporary!(
            created_by: current_user,
            purpose: find_purpose
          )

          redirect_to new_provider_select_path(provider_id: provider.id)
        else
          render :new
        end
      end

    private

      def find_form_params
        params.expect(find: [:postcode, :building_name_or_number])
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

