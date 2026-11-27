module Accreditations
  class EndDateRequiredController < ::CheckController
    include FormObjectSavePattern
    include AccreditationJourneyController

    helper_method :form_url

    def new
      @provider = provider
      @form = Accreditations::EndDateRequiredForm.new

      authorize provider, :update?
    end

    def create
      @form = Accreditations::EndDateRequiredForm.new(accreditation_form_params)

      authorize provider, :update?

      if @form.valid?
        if @form.end_date_required?
          redirect_to provider_new_accreditation_end_date_path(provider_id: provider.id)
        else
          accreditation_session.add_attributes({ "end_date" => nil,
                                                 "end_date_day" => nil,
                                                 "end_date_month" => nil,
                                                 "end_date_year" => nil })
          redirect_to new_accreditation_confirm_path(provider_id: provider.id)
        end
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

    def form_url
      if setup_context?
        providers_setup_accreditations_end_date_required_path
      else
        provider_new_accreditation_end_date_required_path
      end
    end

    def accreditation_form_params
      params.expect(accreditations_end_date_required_form: [:end_date_required])
    end
  end
end
