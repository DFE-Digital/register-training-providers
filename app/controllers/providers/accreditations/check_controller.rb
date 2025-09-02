module Providers
  module Accreditations
    class CheckController < ::CheckController
      before_action :load_provider

    private

      def load_provider
        @provider = policy_scope(Provider).find_by!(uuid: params[:provider_id])
      end

      def purpose
        :create_accreditation
      end

      def success_path
        provider_accreditations_path(@provider)
      end

      def cancel_path
        success_path
      end

      def model_class
        ::Providers::Accreditation
      end

      def save
        accreditation = @provider.accreditations.build(model.attributes.slice("number", "start_date", "end_date"))
        authorize accreditation

        if accreditation.save
          current_user.clear_temporary(model_class, purpose:)
          redirect_to success_path, flash: flash_message
        else
          redirect_to back_path
        end
      end

      def new_model_path(query_params = {})
        new_provider_accreditation_path(@provider, query_params)
      end

      def new_model_check_path
        provider_accreditation_confirm_path(@provider)
      end
    end
  end
end
