module Accreditations
  class EndDateController < ApplicationController
    include FormObjectSavePattern
    include AccreditationJourneyController

    helper_method :form_url

    def new
      accreditation_session.load_accreditation
      @provider = provider
      @form = Accreditations::EndDateForm.new

      authorize provider, :update?
    end

    def create
      @form = Accreditations::EndDateForm.new(accreditation_form_params)
      authorize provider, :update?

      if @form.valid?
        accreditation_session.add_attributes(@form.attributes)
        redirect_to success_path
      else
        @provider = provider
        render :new
      end
    end

  private

    def provider
      @provider ||= Provider.find(params[:provider_id])
    end

    def back_path
      provider_new_accreditation_end_date_required_path(provider_id: provider.id)
    end

    def form_url
      provider_new_accreditation_end_date_path(provider_id: provider.id)
    end

    def success_path
      new_accreditation_confirm_path(provider_id: provider.id)
    end

    def accreditation_form_params
      params.expect(accreditation: [*Accreditations::EndDateForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| Accreditations::EndDateForm::PARAM_CONVERSION.fetch(k, k) }
    end
  end
end
