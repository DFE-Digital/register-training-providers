module Providers
  module Accreditations
    class CheckController < ::CheckController
      before_action :load_provider

    private

      def load_provider
        @provider = policy_scope(Provider).find_by!(uuid: params[:provider_id])
      end

      def model_class
        Providers::Accreditation
      end

      def model_uuid
        @model_uuid ||= params[:id] || params[:accreditation_id]
      end

      def purpose
        model_uuid.present? ? :"edit_accreditation_#{model_uuid}" : :"create_accreditation_#{@provider.uuid}"
      end

      def model
        @model ||= current_user.load_temporary(model_class, purpose:)
      end

      def success_path
        provider_accreditations_path(@provider)
      end

      def save
        if model_uuid.present?
          accreditation = @provider.accreditations.kept.find_by!(uuid: model_uuid)
          authorize accreditation

          if accreditation.update(model.to_accreditation_attributes)
            current_user.clear_temporary(model_class, purpose:)
            redirect_to success_path, flash: flash_message
          else
            redirect_to back_path
          end
        else
          accreditation = @provider.accreditations.build(model.to_accreditation_attributes)
          authorize accreditation

          if accreditation.save
            current_user.clear_temporary(model_class, purpose:)
            redirect_to success_path, flash: flash_message
          else
            redirect_to back_path
          end
        end
      end

      def new_model_path(query_params = {})
        new_provider_accreditation_path(@provider, query_params)
      end

      def edit_model_path(query_params = {})
        accreditation = @provider.accreditations.kept.find_by!(uuid: model_uuid)
        edit_provider_accreditation_path(@provider, accreditation, query_params)
      end

      def new_model_check_path
        provider_accreditation_confirm_path(@provider)
      end

      def model_check_path
        accreditation = @provider.accreditations.kept.find_by!(uuid: model_uuid)
        provider_accreditation_check_path(@provider, accreditation)
      end
    end
  end
end
