module Providers
  module Partnerships
    class EditJourneyController < ApplicationController
      include PartnershipSteps

      def new
        authorize partnership

        return redirect_to(first_step_path) unless wizard.valid_path_to_current_step?

        seed_state if wizard.state_store.read.blank?

        prepare_step
        render template_for_step
      end

      def update
        authorize partnership

        return redirect_to(first_step_path) unless wizard.valid_path_to_current_step?

        unless wizard.save_current_step
          prepare_step
          return render(template_for_step, status: :unprocessable_content)
        end

        return save_partnership if wizard.check_your_answers?

        redirect_to wizard.next_step_path(return_to_review: params[:return_to_review])
      end

    private

      def first_step_path
        provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id)
      end

      def seed_state
        wizard.clear_state
        wizard.seed_from_partnership
      end

      def save_partnership
        unless partnership.update(wizard.partnership_form.to_partnership_attributes)
          prepare_step
          flash.now[:alert] = partnership_save_failure_message(partnership)
          return render(template_for_step, status: :unprocessable_content)
        end

        wizard.clear_state
        redirect_to provider_partnerships_path(provider),
                    flash: { success: I18n.t("flash_message.success.check.partnership.update") }
      end

      def prepare_step
        @wizard = wizard
        @form = wizard.current_step
        @form_url = wizard.current_step_path(return_to_review: params[:return_to_review])
        @form_method = :patch
        @back_path = wizard.previous_step_path(fallback: provider_partnerships_path(provider))
        @cancel_path = provider_partnerships_path(provider)
        @page_caption = provider.operating_name.to_s
        @page_subtitle = provider.operating_name.to_s
        @page_title = page_title_for_step
        @provider_accredited = provider.accredited?

        @academic_years = eligible_academic_years if wizard.current_step_name == :academic_years

        prepare_check_your_answers if wizard.check_your_answers?
      end

      def prepare_check_your_answers
        @form = wizard.partnership_form
        @partnership_types = partnership.partnership_types.kept.pluck(:partnership_type)
        @save_path = wizard.current_step_path
        @save_button_text = "Save partnership"
        @change_paths = {
          dates: change_step_path(:dates),
          academic_years: change_step_path(:academic_years)
        }
      end

      def change_step_path(step)
        provider_partnership_edit_step_path(
          provider_id: provider.id,
          partnership_id: partnership.id,
          step: step.to_s.tr("_", "-"),
          return_to_review: "true"
        )
      end

      def provider
        @provider ||= Provider.kept.find(params.expect(:provider_id))
      end

      def partnership
        @partnership ||= provider.partnerships.kept.find(params.expect(:partnership_id))
      end

      def repository
        @repository ||= DfE::Wizard::Repository::Session.new(
          session: session,
          key: :"partnership_edit_#{partnership.id}"
        )
      end

      def state_store
        @state_store ||= ::Partnerships::StateStores::PartnershipStore.new(repository:)
      end

      def wizard
        @wizard ||= ::Partnerships::EditWizard.new(
          provider: provider,
          partnership: partnership,
          current_step: current_step,
          current_step_params: params,
          state_store: state_store
        )
      end

      def current_step
        params[:step]&.tr("-", "_")&.to_sym
      end
    end
  end
end
