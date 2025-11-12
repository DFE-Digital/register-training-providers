module Providers
  module Addresses
    class CheckController < ApplicationController
      def show
        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        address_data = address_session.load_address
        @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.from_address(@address)

        if @form.invalid?
          redirect_to provider_edit_address_path(@address, provider_id: provider.id, goto: "confirm")
          return
        end

        @presenter = AddressJourney::CheckPresenter.new(
          model: @form,
          provider: provider,
          context: :edit,
          address: @address,
          goto_param: params[:goto],
          search_available: search_available?,
          manual_entry_only: manual_entry_only?
        )
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

        @presenter = AddressJourney::CheckPresenter.new(
          model: @form,
          provider: provider,
          context: :new,
          goto_param: params[:goto],
          search_available: search_available?,
          manual_entry_only: manual_entry_only?
        )
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

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end

      def address_session
        @address_session ||= AddressJourney::SessionManager.new(session, context: :manage)
      end

      def search_available?
        address_session.search_results_available?
      end

      def manual_entry_only?
        address_session.manual_entry?
      end
    end
  end
end
