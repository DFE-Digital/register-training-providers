module Accreditations
  class DeletesController < ApplicationController
    before_action :load_provider_and_accreditation

    def show
      authorize @accreditation
    end

    def destroy
      authorize @accreditation

      @accreditation.discard!

      redirect_to provider_accreditations_path(@provider),
                  flash: { success: I18n.t("flash_message.success.accreditation.deleted") }
    end

  private

    def load_provider_and_accreditation
      @provider = policy_scope(Provider).find(params[:provider_id])
      @accreditation = @provider.accreditations.kept.find(params[:accreditation_id])
    end
  end
end
