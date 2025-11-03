module Providers
  module Addresses
    class CheckController < ::CheckController
      include FormObjectSavePattern

      before_action :set_presenter, only: %i[new show]

      def show
      end

      def new
        redirect_to back_path if model.invalid?
      end

    private

      def set_presenter
        @presenter = AddressJourney::CheckPresenter.new(
          model:,
          provider:,
          context:,
          address:
        )
      end

      def model_class
        AddressForm
      end

      def model_id
        @model_id ||= params[:id] || params[:address_id]
      end

      def purpose
        if model_id.present?
          :"edit_address_#{model_id}"
        else
          :create_address
        end
      end

      def model
        @model ||= current_user.load_temporary(model_class, purpose:)
      end

      def success_path
        provider_addresses_path(provider)
      end

      def find_existing_record
        provider.addresses.kept.find(model_id)
      end

      def build_new_record
        provider.addresses.build(model_attributes)
      end

      def model_attributes
        model.to_address_attributes
      end

      def new_model_path(query_params = {})
        provider_new_address_path(query_params.merge(provider_id: provider.id))
      end

      def edit_model_path(query_params = {})
        address = provider.addresses.kept.find(model_id)
        provider_edit_address_path(address, query_params.merge(provider_id: provider.id))
      end

      def new_model_check_path
        provider_new_address_confirm_path(provider)
      end

      def model_check_path
        provider_address_check_path(model_id, provider_id: provider.id)
      end

      def change_path
        if model_id.present?
          edit_model_path(goto: "confirm")
        else
          new_model_path(goto: "confirm")
        end
      end

      def context
        if model_id.present?
          :edit
        else
          :new
        end
      end

      def address
        return nil if model_id.blank?

        @address ||= provider.addresses.kept.find(model_id)
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end
    end
  end
end
