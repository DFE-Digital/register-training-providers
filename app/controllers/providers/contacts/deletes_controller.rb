module Providers
  module Contacts
    class DeletesController < ApplicationController
      def show
        authorize contact
      end

      def destroy
        authorize contact

        contact.discard!

        redirect_to provider_contacts_path(provider),
                    flash: { success: I18n.t("flash_message.success.contact.deleted") }
      end

    private

      def contact
        @contact ||= provider.contacts.kept.find(params[:contact_id])
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
