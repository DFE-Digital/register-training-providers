module Providers
  module Addresses
    class SelectController < ApplicationController
      def new
        search_data = address_session.load_search

        unless search_data
          redirect_to find_path
          return
        end

        @results = search_data[:results] || []

        # Pre-select the radio button if returning to this page with a stored address
        @form = prepare_select_form

        context = setup_context? ? :setup : :manage
        @presenter = AddressJourney::SelectPresenter.new(
          results: @results,
          postcode: search_data[:postcode],
          building_name_or_number: search_data[:building_name_or_number],
          provider: provider,
          goto_param: params[:goto],
          back_path: back_path,
          context: context
        )
      end

      def create
        # Validate the SelectForm first
        @form = ::Addresses::SelectForm.new(selected_address_index: params.dig(:select, :selected_address_index))

        unless @form.valid?
          render_select_form
          return
        end

        search_data = address_session.load_search
        unless search_data
          redirect_to find_path, alert: t("controllers.providers.addresses.select.no_search_data")
          return
        end

        results = search_data[:results]
        index = @form.selected_address_index.to_i

        unless index >= 0 && index < results.size
          @form.errors.add(:selected_address_index, "is invalid")
          render_select_form
          return
        end

        selected = results[index]
        address_form = AddressForm.from_os_address(selected.symbolize_keys)
        address_form.provider_id = provider.id unless setup_context?
        address_form.provider_creation_mode = setup_context?

        # NOTE: No validation check needed here - OS API returns valid data
        # If validation fails, it's a system error that should bubble up

        address_session.store_address(address_form.attributes)
        redirect_to success_path
      end

    private

      def render_select_form
        search_data = address_session.load_search
        @results = search_data[:results] || []
        # @form already set in create action (with validation errors if invalid)
        context = setup_context? ? :setup : :manage
        @presenter = AddressJourney::SelectPresenter.new(
          results: @results,
          postcode: search_data[:postcode],
          building_name_or_number: search_data[:building_name_or_number],
          provider: provider,
          goto_param: params[:goto],
          back_path: back_path,
          context: context
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

      def prepare_select_form
        selected_index = find_previously_selected_index
        ::Addresses::SelectForm.new(selected_address_index: selected_index)
      end

      def find_previously_selected_index
        stored_address = address_session.load_address
        return nil unless stored_address

        search_data = address_session.load_search
        return nil unless search_data

        results = search_data[:results]
        return nil unless results

        # Match by address_line_1 and postcode
        results.each_with_index do |result, index|
          if result["address_line_1"] == stored_address["address_line_1"] &&
              result["postcode"] == stored_address["postcode"]
            return index
          end
        end

        nil
      end
    end
  end
end
