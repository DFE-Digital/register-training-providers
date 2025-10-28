module Providers
  module Contacts
    class CheckController < ::CheckController
      include FormObjectSavePattern

      def new
        redirect_to back_path if model.invalid?
      end

    private

      def model_class
        ContactForm
      end

      def model_id
        @model_id ||= params[:id] || params[:contact_id]
      end

      def purpose
        model_id.present? ? :"edit_contact_#{model_id}" : :create_contact
      end

      def model
        @model ||= current_user.load_temporary(model_class, purpose:)
      end

      def success_path
        provider_contacts_path(provider)
      end

      def find_existing_record
        provider.contacts.kept.find(model_id)
      end

      def build_new_record
        provider.contacts.build(model_attributes)
      end

      def model_attributes
        model.to_contact_attributes
      end

      def new_model_path(query_params = {})
        new_provider_contact_path(query_params.merge(provider_id: provider.id))
      end

      def edit_model_path(query_params = {})
        contact = provider.contacts.kept.find(model_id)
        edit_provider_contact_path(contact, query_params.merge(provider_id: provider.id))
      end

      def new_model_check_path
        provider_contact_confirm_path(provider_id: provider.id)
      end

      def model_check_path
        provider_contact_check_path(model_id, provider_id: provider.id)
      end

      def change_path
        if model_id.present?
          edit_model_path(goto: "confirm")
        else
          new_model_path(goto: "confirm")
        end
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
