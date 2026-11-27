module Accreditations
  class StartDateController < ::CheckController
    include FormObjectSavePattern
    include AccreditationJourneyController

    def new
      accreditation_data = accreditation_session.load_accreditation
      @provider = provider
      @form = Accreditations::StartDateForm.new(start_date: accreditation_data[:start_date])
      @form.provider_id = provider.id

      authorize provider, :update?
    end

    def create
      @form = Accreditations::StartDateForm.new(accreditation_form_params)
      @form.provider_id = provider.id
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
      provider_new_accreditation_start_date_path(provider_id: provider.id)
    end

    def success_path
      provider_new_accreditation_end_date_required_path(provider_id: provider.id)
    end

    def accreditation_form_params
      params.expect(accreditation: [*Accreditations::StartDateForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| Accreditations::StartDateForm::PARAM_CONVERSION.fetch(k, k) }
    end
  end
end
