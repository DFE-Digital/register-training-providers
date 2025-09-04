module Providers
  module Accreditations
    class DeletesController < CheckController
      before_action :load_provider
      before_action :load_accreditation

      def show
        authorize @accreditation, :destroy?
      end

      def destroy
        authorize @accreditation, :destroy?
        @accreditation.discard!
        redirect_to(provider_accreditations_path(@provider),
                    flash: { success: t("flash_message.success.accreditation.remove") })
      end

    private

      def load_provider
        @provider = policy_scope(Provider).find_by!(uuid: params[:provider_id])
      end

      def load_accreditation
        @accreditation = @provider.accreditations.find_by!(uuid: params[:accreditation_id])
      end
    end
  end
end
