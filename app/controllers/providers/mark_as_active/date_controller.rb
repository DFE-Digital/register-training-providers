module Providers
  class MarkAsActive::DateController < ApplicationController
    helper_method :back_path
    helper_method :inactive_period

    def show
      authorize provider, :mark_as_active?

      @form = Providers::MarkAsActive::DateForm.new(
        end_date: end_date,
        start_date: inactive_period["start_date"]
      )
    end

    def create
      authorize provider, :mark_as_active?

      @form = Providers::MarkAsActive::DateForm.new(
        active_date_params.merge(start_date: inactive_period["start_date"].to_date)
      )

      if @form.valid?
        inactive_period[:end_date] = @form.end_date

        provider.save_as_temporary!(created_by: current_user, purpose: :edit_provider)
        redirect_to provider_mark_as_active_check_path(provider)
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

    def active_date_params
      params.expect(providers_mark_as_active_date_form: [*Providers::MarkAsActive::DateForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| Providers::MarkAsActive::DateForm::PARAM_CONVERSION.fetch(k, k) }
    end

    def end_date
      inactive_period["end_date"]
    end

    def inactive_period
      return provider.current_inactive_period unless provider.current_inactive_period.nil?

      provider.latest_complete_inactive_period
    end
  end
end
