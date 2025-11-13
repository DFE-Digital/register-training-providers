module Providers
  module Addresses
    class ManualEntryController < ApplicationController
      include AddressJourneyController

      def new
        # Setup mode specific validation
        if setup_context? && (provider.nil? || provider.invalid?)
          redirect_to new_provider_details_path
          return
        end

        unless params[:skip_finder] == "true"
          redirect_to find_path
          return
        end

        # Clear session only when starting completely fresh
        should_clear = params[:skip_finder].blank? && params[:goto].blank? && params[:from].blank?
        address_session.clear! if should_clear

        address_data = address_session.load_address
        @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.new
        @form.provider_id = provider.id unless setup_context?

        setup_manual_entry_view_data(:new)
      end

      def edit
        # Edit only available in manage context
        redirect_to provider_addresses_path(provider) if setup_context?

        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        # Load from session if user is returning from check page with temporary changes
        address_data = address_session.load_address
        @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.from_address(@address)
        setup_manual_entry_view_data(:edit)
      end

      def create
        @form = AddressForm.new(address_params)
        @form.provider_id = provider.id unless setup_context?
        @form.manual_entry = true if @form.respond_to?(:manual_entry=)
        @form.provider_creation_mode = setup_context?

        if @form.valid?
          coordinates = ::Addresses::GeocodeService.call(postcode: @form.postcode)
          @form.latitude = coordinates[:latitude]
          @form.longitude = coordinates[:longitude]

          address_session.store_address(@form.attributes)
          redirect_to success_path
        else
          setup_manual_entry_view_data(:new)
          render :new
        end
      end

      def update
        # Update only available in manage context
        redirect_to provider_addresses_path(provider) if setup_context?

        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        @form = ::AddressForm.new(address_params)
        @form.provider_id = provider.id

        if @form.valid?
          coordinates = ::Addresses::GeocodeService.call(postcode: @form.postcode)
          @form.latitude = coordinates[:latitude]
          @form.longitude = coordinates[:longitude]

          address_session.store_address(@form.attributes)
          redirect_to provider_address_check_path(@address, provider_id: provider.id)
        else
          setup_manual_entry_view_data(:edit)
          render :edit
        end
      end

    private

      def address_params
        params.expect(address: [:address_line_1,
                                :address_line_2,
                                :address_line_3,
                                :town_or_city,
                                :county,
                                :postcode,
                                :provider_id])
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
            journey_coordinator(:address_manual_entry).next_path
          end
        else
          provider_new_address_confirm_path(provider)
        end
      end

      def back_path
        setup_context? ? journey_coordinator(:address_manual_entry).back_path : manage_back_path
      end

      def manage_back_path
        # Edit mode
        if params[:id]
          if params[:goto] == "confirm"
            address = provider.addresses.kept.find(params[:id])
            provider_address_check_path(address, provider_id: provider.id)
          else
            provider_addresses_path(provider)
          end
        # Coming from select page
        elsif params[:from] == "select"
          query_params = {}
          query_params[:goto] = params[:goto] if params[:goto].present?
          provider_new_select_path(provider, query_params)
        # Coming from check page (change flow)
        elsif params[:goto] == "confirm"
          provider_new_address_confirm_path(provider)
        # Default - from find page
        else
          provider_new_find_path(provider)
        end
      end

      def manual_entry_form_url
        form_params = {}
        form_params[:goto] = params[:goto] if params[:goto].present?
        form_params[:from] = "select" if params[:from] == "select"
        if setup_context?
          providers_setup_addresses_address_path(form_params)
        else
          provider_addresses_path(provider, form_params)
        end
      end

      def manual_entry_form_url_edit
        form_params = { provider_id: provider.id }
        form_params[:goto] = params[:goto] if params[:goto].present?
        provider_address_path(@address, form_params)
      end

      def manual_entry_cancel_path
        setup_context? ? providers_path : provider_addresses_path(provider)
      end

      def manual_entry_page_title(context)
        if setup_context?
          "Add address"
        elsif context == :edit
          provider.operating_name.to_s
        else
          "Add address - #{provider.operating_name}"
        end
      end

      def manual_entry_page_subtitle(context)
        if setup_context?
          "Add provider"
        elsif context == :edit
          "Edit address"
        else
          "Add address"
        end
      end

      def manual_entry_page_caption(context)
        if setup_context?
          "Add provider"
        elsif context == :edit
          provider.operating_name.to_s
        else
          "Add address - #{provider.operating_name}"
        end
      end

      def setup_manual_entry_view_data(context)
        @back_path = back_path
        @cancel_path = manual_entry_cancel_path
        @page_title = manual_entry_page_title(context)
        @page_subtitle = manual_entry_page_subtitle(context)
        @page_caption = manual_entry_page_caption(context)

        if context == :edit
          @form_url = manual_entry_form_url_edit
          @form_method = :patch
        else
          @form_url = manual_entry_form_url
          @form_method = :post
        end
      end
    end
  end
end
