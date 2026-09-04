module Providers
  class MarkAsInactive::DateController < ApplicationController
    helper_method :back_path

    def show
      authorize provider, :mark_as_inactive?

      @form = Providers::MarkAsInactive::DateForm.new(start_date:)
    end

    def create
      authorize provider, :mark_as_inactive?

      @form = Providers::MarkAsInactive::DateForm.new(inactive_date_params)

      if @form.valid?
        if provider.inactive?
          provider.current_inactive_period[:start_date] = @form.start_date
        else
          provider.inactive_periods << { start_date: @form.start_date, end_date: nil }
        end

        provider.save_as_temporary!(created_by: current_user, purpose: :edit_provider)
        redirect_to provider_mark_as_inactive_reasons_path(provider)
      else
        render :show
      end
    end

  private

    def back_path
      provider_path(provider)
    end

    def provider
      @provider ||= current_user.load_temporary(Provider, id: params[:provider_id], purpose: :edit_provider)
    end

    def inactive_date_params
      params.expect(providers_mark_as_inactive_date_form: [*Providers::MarkAsInactive::DateForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| Providers::MarkAsInactive::DateForm::PARAM_CONVERSION.fetch(k, k) }
    end

    def start_date
      return nil unless provider.inactive?

      provider.current_inactive_period["start_date"]
    end
  end
end
