module Providers
  module Addresses
    class CheckController < ApplicationController
      include AddressJourneyController

      def show
        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        address_data = address_session.load_address
        @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.from_address(@address)

        if @form.invalid?
          redirect_to provider_edit_address_path(@address, provider_id: provider.id, goto: "confirm")
          return
        end

        setup_check_view_data(:edit)
      end

      def new
        address_data = address_session.load_address

        unless address_data
          redirect_to provider_new_address_path(provider, skip_finder: "true")
          return
        end

        @form = ::AddressForm.new(address_data)
        @form.provider_id = provider.id

        if @form.invalid?
          redirect_to provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
          return
        end

        setup_check_view_data(:new)
      end

      def create
        address_data = address_session.load_address

        unless address_data
          redirect_to provider_new_address_path(provider, skip_finder: "true")
          return
        end

        @form = ::AddressForm.new(address_data)
        @form.provider_id = provider.id

        address = provider.addresses.build(@form.to_address_attributes)
        authorize address

        if address.save
          address_session.clear!
          redirect_to provider_addresses_path(provider),
                      flash: { success: I18n.t("flash_message.success.check.address.add") }
        else
          redirect_to provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
        end
      end

      def update
        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        address_data = address_session.load_address
        @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.from_address(@address)

        if @address.update(@form.to_address_attributes)
          address_session.clear!
          redirect_to provider_addresses_path(provider),
                      flash: { success: I18n.t("flash_message.success.check.address.update") }
        else
          redirect_to provider_edit_address_path(@address, provider_id: provider.id, goto: "confirm")
        end
      end

    private

      def search_available?
        search_data = address_session.load_search
        search_data.present? && search_data[:results]&.any?
      end

      def manual_entry_only?
        address_data = address_session.load_address
        address_data&.dig(:manual_entry) == true || address_data&.dig("manual_entry") == true
      end

      def edit_context?
        params[:id].present?
      end

      def back_path
        if params[:goto] == "confirm"
          # Coming from check page after editing - return to check
          if edit_context?
            provider_address_check_path(@address, provider_id: provider.id)
          else
            provider_new_address_confirm_path(provider)
          end
        elsif edit_context?
          provider_edit_address_path(@address, provider_id: provider.id, goto: "confirm")
        elsif search_available? && !manual_entry_only?
          # User used finder, go back to select page
          provider_new_select_path(provider)
        else
          # User did manual entry or no search available
          provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
        end
      end

      def change_path
        if edit_context?
          provider_edit_address_path(@address, provider_id: provider.id, goto: "confirm")
        elsif search_available? && !manual_entry_only?
          provider_new_select_path(provider, goto: "confirm")
        else
          provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
        end
      end

      def save_path
        if edit_context?
          provider_address_check_path(@address, provider_id: provider.id)
        else
          provider_address_confirm_path(provider)
        end
      end

      def check_cancel_path
        provider_addresses_path(provider)
      end

      def setup_check_view_data(context)
        @back_path = back_path
        @change_path = change_path
        @save_path = save_path
        @cancel_path = check_cancel_path
        @save_button_text = "Save address"

        if context == :edit
          @form_method = :patch
          @page_subtitle = provider.operating_name.to_s
          @page_caption = provider.operating_name.to_s
        else
          @form_method = :post
          @page_subtitle = "Add address - #{provider.operating_name}"
          @page_caption = "Add address - #{provider.operating_name}"
        end
      end
    end
  end
end
