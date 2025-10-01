module Providers
  module Addresses
    class DeletesController < ApplicationController
      def show
        authorize address
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
    end
  end
end
