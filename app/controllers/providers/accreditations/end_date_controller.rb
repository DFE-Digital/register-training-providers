module Providers
  module Accreditations
    class EndDateController < ::CheckController
      include FormObjectSavePattern
      include AccreditationJourneyController

      helper_method :back_path, :form_url, :cancel_path

      def new
        accreditation_session.load_accreditation
        @provider = provider
        @form = ::Accreditations::EndDateForm.new

        authorize provider, :update?
      end

      def create
        @form = ::Accreditations::EndDateForm.new(accreditation_form_params)
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
        journey_coordinator(:end_date, provider).back_path
      end

      def form_url
        if setup_context?
          providers_setup_accreditations_end_date_path
        else
          provider_new_accreditation_end_date_path
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
          journey_coordinator(:end_date, provider).next_path
        else
          new_accreditation_confirm_path
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
        params.expect(accreditation: [*::Accreditations::EndDateForm::PARAM_CONVERSION.keys])
        .transform_keys { |k| ::Accreditations::EndDateForm::PARAM_CONVERSION.fetch(k, k) }
      end
    end
  end
end
