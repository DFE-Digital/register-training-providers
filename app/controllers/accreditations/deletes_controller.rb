module Accreditations
  class DeletesController < ApplicationController
    before_action :load_accreditation

    def show
      authorize @accreditation
    end

    def destroy
      authorize @accreditation

      @accreditation.discard!

      redirect_to provider_accreditations_path(provider),
                  flash: { success: I18n.t("flash_message.success.accreditation.deleted") }
    end

  private

    def load_accreditation
      @accreditation = provider.accreditations.kept.find(params[:accreditation_id])
    end
  end
end
