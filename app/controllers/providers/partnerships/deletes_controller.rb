module Providers
  module Partnerships
    class DeletesController < ApplicationController
      def show
        authorize partnership

        setup_view_data
      end

      def destroy
        authorize partnership

        partnership.discard!

        redirect_to provider_partnerships_path(provider),
                    flash: { success: I18n.t("flash_message.success.partnership.deleted") }
      end

    private

      def partnership
        @partnership ||= provider.partnerships.kept.find(params[:partnership_id])
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end

      def other_partner
        partnership.other_partner(provider)
      end

      def setup_view_data
        @provider = provider
        @partnership = partnership
        @page_title = "Confirm you want to delete the partnership with #{other_partner.operating_name}"
        @page_subtitle = "Delete partnership - #{@provider.operating_name}"
        @page_caption = "Delete partnership - #{@provider.operating_name}"
        @back_path = provider_partnerships_path(@provider)
        @cancel_path = provider_partnerships_path(@provider)
        @delete_path = provider_partnership_delete_path(@partnership, provider_id: @provider.id)
      end
    end
  end
end
