module Providers
  module Addresses
    class SelectController < ApplicationController
      def new
        search_data = address_session.load_search

        unless search_data
          redirect_to find_path
          return
        end

        # Mark that we came from check page if appropriate
        if params[:goto] == "confirm" && setup_context?
          address_session.mark_from_check!
        end

        @results = search_data[:results] || []

        # Pre-select the radio button if returning to this page with a stored address
        @form = AddressJourney::Selector.prepare_select_form(session_manager: address_session)

        @presenter = AddressJourney::SelectPresenter.new(
          results: @results,
          postcode: search_data[:postcode],
          building_name_or_number: search_data[:building_name_or_number],
          provider:,
          error: nil,
          goto_param: params[:goto],
          back_path:
        )
      end

      def create
        # Validate the SelectForm first
        @form = ::Addresses::SelectForm.new(selected_address_index: params.dig(:select, :selected_address_index))

        unless @form.valid?
          render_select_form
          return
        end

        result = AddressJourney::Selector.call(
          selected_index: @form.selected_address_index,
          session_manager: address_session,
          provider_id: setup_context? ? nil : provider.id
        )

        if result[:success]
          redirect_to success_path
        elsif result[:error] == :missing_search
          redirect_to find_path, alert: "Please search for an address first"
        else
          flash.now[:alert] = "Please select a valid address"
          render_select_form
        end
      end

    private

      def render_select_form
        search_data = address_session.load_search
        @results = search_data[:results] || []
        # @form already set in create action (with validation errors if invalid)
        @presenter = AddressJourney::SelectPresenter.new(
          results: @results,
          postcode: search_data[:postcode],
          building_name_or_number: search_data[:building_name_or_number],
          provider:,
          error: flash.now[:alert],
          goto_param: params[:goto],
          back_path:
        )
        render :new
      end

      def provider
        @provider ||= if params[:provider_id]
                        Provider.find(params[:provider_id])
                      else
                        provider_session.load_provider || Provider.new
                      end
      end

      def setup_context?
        params[:provider_id].blank?
      end

      def address_session
        context = setup_context? ? :setup : :manage
        @address_session ||= AddressJourney::SessionManager.new(session, context:)
      end

      def provider_session
        @provider_session ||= ProviderCreation::SessionManager.new(session)
      end

      def journey_coordinator
        @journey_coordinator ||= ProviderCreation::JourneyCoordinator.new(
          current_step: :address_select,
          session_manager: provider_session,
          provider: provider,
          from_check: params[:goto] == "confirm",
          address_session: address_session
        )
      end

      def find_path
        if setup_context?
          providers_setup_addresses_find_path(goto: params[:goto])
        else
          provider_new_find_path(provider)
        end
      end

      def success_path
        if setup_context?
          # If coming from check page, return to check
          if params[:goto] == "confirm"
            new_provider_confirm_path
          else
            journey_coordinator.next_path
          end
        else
          provider_new_address_confirm_path(provider)
        end
      end

      def back_path
        setup_context? ? journey_coordinator.back_path : manage_back_path
      end

      def manage_back_path
        provider_new_find_path(provider)
      end
    end
  end
end
