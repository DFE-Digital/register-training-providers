module Providers
  module Setup
    module Addresses
      class SelectController < ApplicationController
        def new
          search_data = address_session.load_search

          unless search_data
            redirect_to providers_setup_addresses_find_path(goto: params[:goto])
            return
          end

          # Mark that we came from check page if appropriate
          if params[:goto] == "confirm"
            address_session.mark_from_check!
          end

          @results = search_data[:results] || []

          # Pre-select the radio button if returning to this page with a stored address
          @form = AddressJourney::Selector.prepare_select_form(session_manager: address_session)

          @presenter = AddressJourney::Setup::SelectPresenter.new(
            results: @results,
            postcode: search_data[:postcode],
            building_name_or_number: search_data[:building_name_or_number],
            provider: provider,
            error: nil,
            goto_param: params[:goto],
            back_path: journey_coordinator.back_path
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
            provider_id: nil
          )

          if result[:success]
            # If coming from check page, return to check
            if params[:goto] == "confirm"
              redirect_to new_provider_confirm_path
            else
              redirect_to journey_coordinator.next_path
            end
          elsif result[:error] == :missing_search
            redirect_to providers_setup_addresses_find_path(goto: params[:goto]),
                        alert: "Please search for an address first"
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
          @presenter = AddressJourney::Setup::SelectPresenter.new(
            results: @results,
            postcode: search_data[:postcode],
            building_name_or_number: search_data[:building_name_or_number],
            provider: provider,
            error: flash.now[:alert],
            goto_param: params[:goto],
            back_path: journey_coordinator.back_path
          )
          render :new
        end

        def provider
          @provider ||= provider_session.load_provider || Provider.new
        end

        def address_session
          @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
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
      end
    end
  end
end
