module Providers
  module Addresses
    class FindController < ApplicationController
      include AddressJourneyController

      def new
        # Clear session when starting a fresh journey (no goto param means not navigating within existing journey)
        address_session.clear! if params[:goto].blank?

        # Pre-fill form with previous search if available
        search_data = address_session.load_search
        @form = if search_data
                  ::Addresses::FindForm.new(
                    postcode: search_data[:postcode],
                    building_name_or_number: search_data[:building_name_or_number]
                  )
                else
                  ::Addresses::FindForm.new
                end

        setup_view_data
      end

      def create
        @form = ::Addresses::FindForm.new(
          postcode: params.dig(:find, :postcode),
          building_name_or_number: params.dig(:find, :building_name_or_number)
        )

        if @form.valid?
          results = OrdnanceSurvey::AddressLookupService.call(
            postcode: @form.postcode,
            building_name_or_number: @form.building_name_or_number
          )

          address_session.store_search(
            postcode: @form.postcode,
            building_name_or_number: @form.building_name_or_number,
            results: results
          )

          redirect_to select_path
        else
          setup_view_data
          render :new
        end
      end

    private

      def select_path
        if setup_context?
          providers_setup_addresses_select_path(goto: params[:goto])
        else
          provider_new_select_path(provider)
        end
      end

      def back_path
        setup_context? ? journey_coordinator(:address_find).back_path : manage_back_path
      end

      def manage_back_path
        provider_addresses_path(provider)
      end

      def form_url
        setup_context? ? providers_setup_addresses_find_path : provider_find_path(provider)
      end

      def cancel_path
        setup_context? ? providers_path : provider_addresses_path(provider)
      end

      def manual_entry_path
        if setup_context?
          providers_setup_addresses_address_path(skip_finder: "true")
        else
          provider_new_address_path(provider, skip_finder: "true")
        end
      end

      def page_subtitle
        setup_context? ? "Add provider" : provider.operating_name.to_s
      end

      def page_caption
        setup_context? ? "Add provider" : nil
      end

      def setup_view_data
        @back_path = back_path
        @form_url = form_url
        @cancel_path = cancel_path
        @manual_entry_path = manual_entry_path
        @page_title = "Find address"
        @page_subtitle = page_subtitle
        @page_caption = page_caption
      end
    end
  end
end
