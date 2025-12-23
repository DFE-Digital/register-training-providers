module Providers
  module Partnerships
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

        setup_view_data(search_data)
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
        address_session.store_address(address_form.attributes)
        redirect_to success_path
      end

    private

      def render_select_form
        search_data = address_session.load_search
        @results = search_data[:results] || []
        setup_view_data(search_data)
        render :new
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
            journey_coordinator(:address_select).next_path
          end
        else
          provider_new_address_confirm_path(provider)
        end
      end

      def back_path
        setup_context? ? journey_coordinator(:address_select).back_path : manage_back_path
      end

      def manage_back_path
        if params[:goto] == "confirm"
          provider_new_address_confirm_path(provider)
        else
          provider_new_find_path(provider)
        end
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

      def form_url
        options = {}
        options[:goto] = params[:goto] if params[:goto].present?

        if setup_context?
          providers_setup_addresses_select_path(options)
        else
          provider_select_path(provider, options)
        end
      end

      def change_search_path
        if setup_context?
          options = {}
          options[:goto] = params[:goto] if params[:goto].present?
          providers_setup_addresses_find_path(options)
        else
          provider_new_find_path(provider)
        end
      end

      def manual_entry_path
        query_params = { skip_finder: "true" }
        search_data = address_session.load_search
        results = search_data&.dig(:results) || []
        query_params[:from] = "select" if results.present?
        query_params[:goto] = params[:goto] if params[:goto].present?

        if setup_context?
          providers_setup_addresses_address_path(query_params)
        else
          provider_new_address_path(provider, query_params)
        end
      end

      def cancel_path
        setup_context? ? providers_path : provider_addresses_path(provider)
      end

      def page_subtitle
        setup_context? ? "Add provider" : provider.operating_name.to_s
      end

      def page_caption
        setup_context? ? "Add provider" : "Add address - #{provider.operating_name}"
      end

      def setup_view_data(search_data)
        @presenter = AddressJourney::SelectPresenter.new(
          results: @results,
          postcode: search_data[:postcode],
          building_name_or_number: search_data[:building_name_or_number]
        )
        @back_path = back_path
        @form_url = form_url
        @change_search_path = change_search_path
        @manual_entry_path = manual_entry_path
        @cancel_path = cancel_path
        @page_subtitle = page_subtitle
        @page_caption = page_caption
      end
    end
  end
end
