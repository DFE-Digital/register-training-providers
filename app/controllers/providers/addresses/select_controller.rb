module Providers
  module Addresses
    class SelectController < ApplicationController
      def new
        search_data = address_session.load_search

        unless search_data
          redirect_to provider_new_find_path(provider)
          return
        end

        @results = search_data[:results] || []

        # Pre-select the radio button if returning to this page with a stored address
        @form = AddressJourney::Selector.prepare_select_form(session_manager: address_session)

        @presenter = AddressJourney::SelectPresenter.new(
          results: @results,
          postcode: search_data[:postcode],
          building_name_or_number: search_data[:building_name_or_number],
          provider: provider,
          error: nil,
          goto_param: params[:goto]
        )
      end

      def create
        @form = ::Addresses::SelectForm.new(selected_address_index: params.dig(:select, :selected_address_index))

        unless @form.valid?
          render_select_form
          return
        end

        result = AddressJourney::Selector.call(
          selected_index: @form.selected_address_index,
          session_manager: address_session,
          provider_id: provider.id
        )

        if result[:success]
          redirect_to provider_new_address_confirm_path(provider)
        elsif result[:error] == :missing_search
          redirect_to provider_new_find_path(provider), alert: "Please search for an address first"
        else
          flash.now[:alert] = "Please select a valid address"
          render_select_form
        end
      end

    private

      def render_select_form
        search_data = address_session.load_search
        @results = search_data[:results] || []
        @presenter = AddressJourney::SelectPresenter.new(
          results: @results,
          postcode: search_data[:postcode],
          building_name_or_number: search_data[:building_name_or_number],
          provider: provider,
          error: flash.now[:alert],
          goto_param: params[:goto]
        )
        render :new
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end

      def address_session
        @address_session ||= AddressJourney::SessionManager.new(session, context: :manage)
      end
    end
  end
end
