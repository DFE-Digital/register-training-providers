module Providers
  module Accreditations
    class StartDateController < ::CheckController
      include FormObjectSavePattern
      include AccreditationJourneyController

      helper_method :back_path, :form_url, :cancel_path

      def new
        accreditation_data = accreditation_session.load_accreditation
        @form = ::Accreditations::StartDateForm.new
        @form.provider_id = accreditation_data[:provider_id]
        @provider = provider
        authorize @form
      end

      def create
        @form = ::Accreditations::StartDateForm.new(accreditation_form_params)
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

      def back_path
        provider = provider_session.load_provider
        journey_coordinator(:start_date, provider).back_path
      end

      def form_url
        if setup_context?
          providers_setup_accreditations_start_date_path
        else
          provider_new_accreditation_start_date_path
        end
      end

      def cancel_path
        if setup_context?
          root_path
        else
          provider_accreditations_path(@provider)
        end
      end

      def success_path
        if setup_context?
          journey_coordinator(:start_date, provider).next_path
        else
          provider_new_accreditation_end_date_required_path(provider_id: provider.id)
        end
      end

      def journey_coordinator(current_step, provider)
        ProviderCreation::JourneyCoordinator.new(
          current_step: current_step,
          session_manager: provider_session,
          provider: provider,
          from_check: params[:goto] == "confirm"
        )
      end

      def accreditation_form_params
        params.expect(accreditation: [*::Accreditations::StartDateForm::PARAM_CONVERSION.keys])
        .transform_keys { |k| ::Accreditations::StartDateForm::PARAM_CONVERSION.fetch(k, k) }
      end
    end
  end
end
