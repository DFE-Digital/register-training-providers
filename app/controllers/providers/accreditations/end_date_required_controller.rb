module Providers
  module Accreditations
    class EndDateRequiredController < ::CheckController
      include FormObjectSavePattern
      include AccreditationJourneyController

      helper_method :back_path, :form_url, :cancel_path

      def new
        accreditation_data = accreditation_session.load_accreditation
        @form = ::Accreditations::EndDateRequiredForm.new
        @provider = provider
        authorize provider, :update?
      end

      def create
        @form = ::Accreditations::EndDateRequiredForm.new(accreditation_form_params)
        authorize provider, :update?

        if @form.valid?
          if @form.end_date_required?
            redirect_to success_path
          else
            redirect_to skip_path
          end
        else
          @provider = provider
          render :new
        end
      end

    private

      def accreditation_form_params
        params.expect(accreditation: [:end_date_required])
      end

      def back_path
        provider = provider_session.load_provider
        journey_coordinator(:end_date_required, provider).back_path
      end

      def form_url
        if setup_context?
          providers_setup_accreditations_end_date_required_path
        else
          provider_new_accreditation_end_date_required_path
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
          journey_coordinator(:end_date_required, provider).next_path
        else
          provider_new_accreditation_end_date_path(provider_id: provider.id)
        end
      end

      def skip_path
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
        params.expect(accreditations_end_date_required_form: [:end_date_required])
      end
    end
  end
end
