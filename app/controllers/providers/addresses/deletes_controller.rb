module Providers
  module Addresses
    class DeletesController < ApplicationController
      def show
        authorize address

        setup_view_data
      end

      def destroy
        authorize address

        address.discard!

        redirect_to provider_addresses_path(provider),
                    flash: { success: I18n.t("flash_message.success.address.deleted") }
      end

    private

      def address
        @address ||= provider.addresses.kept.find(params[:address_id])
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end

      def setup_view_data
        @provider = provider
        @address = address
        @page_title = "Confirm you want to delete #{@provider.operating_name}’s address"
        @page_subtitle = "Delete address"
        @page_caption = "Delete address"
        @back_path = provider_addresses_path(@provider)
        @cancel_path = provider_addresses_path(@provider)
        @delete_path = provider_address_delete_path(@address, provider_id: @provider.id)
      end
    end
  end
end
