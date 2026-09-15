module Providers
  module Addresses
    class TypesController < ApplicationController
      include AddressJourneyController

      helper_method :cancel_path

      def new
        setup_view_data
        address_data = address_session.load_address

        @form = if address_data[:types]
                  ::Addresses::TypesForm.new(types: address_data[:types].map(&:to_sym))
                else
                  ::Addresses::TypesForm.new
                end

        authorize provider, :update?
      end

      def edit
        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        @form = ::Addresses::TypesForm.from_address(@address)
      end

      def create
        # Validate the SelectForm first
        @form = ::Addresses::TypesForm.new(types: params[:types][:types].compact_blank!)
        authorize provider, :update?

        if @form.valid?
          address_session.add_attributes(@form.attributes)

          redirect_to success_path
        else
          setup_view_data
          render :new
        end
      end

      def update
        @form = ::Addresses::TypesForm.new(types: params[:types][:types].compact_blank!)
        @address = provider.addresses.kept.find(params[:id])
        authorize @address, :update?

        if @form.valid?
          address_session.add_attributes(@form.attributes)

          redirect_to provider_address_check_path(@address, provider_id: provider.id)
        else
          setup_view_data
          render :edit
        end
      end

    private

      def success_path
        if setup_context?
          # If coming from check page, return to check
          if params[:goto] == "confirm"
            new_provider_confirm_path
          else
            journey_coordinator(:address_types).next_path
          end
        else
          provider_new_address_confirm_path(provider)
        end
      end

      def back_path
        setup_context? ? journey_coordinator(:address_types).back_path : manage_back_path
      end

      def manage_back_path
        if params[:goto] == "confirm"
          provider_new_address_confirm_path(provider)
        else
          provider_new_find_path(provider, skip_finder: "true")
        end
      end

      def form_url
        if setup_context?
          providers_setup_addresses_types_path
        else
          provider_addresses_types_path
        end
      end

      def cancel_path
        setup_context? ? providers_path : provider_addresses_path(provider)
      end

      def page_subtitle
        setup_context? ? "Add provider" : provider.operating_name.to_s
      end

      def page_caption
        setup_context? ? "Add provider" : "Add address types - #{provider.operating_name}"
      end

      def setup_view_data
        @back_path = back_path
        @form_url = form_url
        @cancel_path = cancel_path
        @page_subtitle = page_subtitle
        @page_caption = page_caption
      end

      def types_params
        params.expect(types: :types)
      end
    end
  end
end
