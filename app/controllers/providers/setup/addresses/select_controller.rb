module Providers
  module Setup
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
          :find_address_create_provider
        end

        def search_results_purpose
          :address_search_results_create_provider
        end

        def find_path
          providers_setup_addresses_find_path
        end

        def confirm_path
          journey_service.next_path
        end

        def setup_address_form(address_form)
          address_form.provider_creation_mode = true
        end

        def address_form_purpose
          :create_provider
        end

        def save_selected_address(address_form)
          address_form.save_as_temporary!(created_by: current_user, purpose: :create_provider)
        end

        def build_select_presenter(results, find_form, error)
          AddressJourney::Setup::SelectPresenter.new(
            results: results,
            find_form: find_form,
            provider: provider,
            error: error,
            goto_param: params[:goto]
          )
        end

        def provider
          @provider ||= current_user.load_temporary(Provider, purpose: :create_provider)
        end

        def journey_service
          @journey_service ||= Providers::CreationJourneyService.new(
            current_step: :address,
            provider: provider,
            goto_param: params[:goto]
          )
        end
      end
    end
  end
end
