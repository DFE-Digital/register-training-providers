module Providers
  module Addresses
    class CheckController < ::CheckController
      def new
        redirect_to back_path if model.invalid?
      end

    private

      def model_class
        AddressForm
      end

      def model_id
        @model_id ||= params[:id] || params[:address_id]
      end

      def purpose
        model_id.present? ? :"edit_address_#{model_id}" : :create_address
      end

      def model
        @model ||= current_user.load_temporary(model_class, purpose:)
      end

      def success_path
        provider_addresses_path(provider)
      end

      def save
        if model_id.present?
          address = provider.addresses.kept.find(model_id)
          authorize address

          if address.update(model.to_address_attributes)
            current_user.clear_temporary(model_class, purpose:)
            redirect_to success_path, flash: flash_message
          else
            redirect_to back_path
          end
        else
          address = provider.addresses.build(model.to_address_attributes)
          authorize address

          if address.save
            current_user.clear_temporary(model_class, purpose:)
            redirect_to success_path, flash: flash_message
          else
            redirect_to back_path
          end
        end
      end

      def new_model_path(query_params = {})
        new_provider_address_path(query_params.merge(provider_id: provider.id))
      end

      def edit_model_path(query_params = {})
        address = provider.addresses.kept.find(model_id)
        edit_provider_address_path(address, query_params.merge(provider_id: provider.id))
      end

      def new_model_check_path
        provider_address_confirm_path(provider_id: provider.id)
      end

      def model_check_path
        address = provider.addresses.kept.find(model_id)
        provider_address_check_path(address, provider_id: provider.id)
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
