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

        if wizard.current_step_name == :end_date_question && removing_end_date?
          return redirect_to provider_partnership_end_date_removal_path(
            partnership,
            provider_id: provider.id,
            return_to_review: params[:return_to_review]
          )
        end

        redirect_to wizard.next_step_path(return_to_review: params[:return_to_review])
      end

    private

      def removing_end_date?
        partnership.duration.end.is_a?(Date) &&
          wizard.state_store.read.with_indifferent_access[:has_end_date].to_s == "false"
      end

      def first_step_path
        provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id)
      end

      def seed_state
        wizard.clear_state
        wizard.seed_from_partnership
      end

      def save_partnership
        form = wizard.partnership_form
        unless form.valid?
          prepare_step
          @form = form
          return render(template_for_step, status: :unprocessable_content)
        end

        unless partnership.update(form.to_partnership_attributes)
          prepare_step
          flash.now[:alert] = partnership_save_failure_message(partnership)
          return render(template_for_step, status: :unprocessable_content)
        end

        wizard.clear_state
        redirect_to provider_partnerships_path(provider),
                    flash: { success: I18n.t("flash_message.success.check.partnership.update",
                                             name: partnership.other_partner(provider).operating_name) }
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
          start_date: change_step_path(:start_date),
          end_date: change_step_path(:end_date_question),
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
        @provider ||= Provider.kept.find(params[:provider_id])
      end

      def partnership
        @partnership ||= provider.partnerships.kept.find(params[:partnership_id])
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
