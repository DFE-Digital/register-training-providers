module Providers
  class MarkAsInactive::ReasonsController < ApplicationController
    helper_method :back_path

    def show
      authorize provider, :mark_as_inactive?

      @form = ::Providers::MarkAsInactive::ReasonsForm.new(
        reasons: reasons_for_inactive
      )
    end

    def create
      authorize provider, :mark_as_inactive?

      @form = ::Providers::MarkAsInactive::ReasonsForm.new(reasons_params)

      if @form.valid?
        provider.current_inactive_period[:reasons_for_inactive] = @form.transformed_reasons

        provider.save_as_temporary!(created_by: current_user, purpose: :edit_provider)

        redirect_to provider_mark_as_inactive_check_path(provider)
      else
        render :show
      end
    end

  private

    def provider
      @provider ||= current_user.load_temporary(Provider, id: params[:provider_id], purpose: :edit_provider)
    end

    def back_path
      provider_mark_as_inactive_path(provider)
    end

    def reasons_params
      params.expect(providers_mark_as_inactive_reasons_form: [:other_reason, { reasons: [] }])
    end

    def reasons_for_inactive
      return [] if provider.current_inactive_period["reasons_for_inactive"].blank?

      provider.current_inactive_period["reasons_for_inactive"]
    end
  end
end
