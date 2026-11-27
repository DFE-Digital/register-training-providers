module Providers
  module Partnerships
    class EditJourneyController < ApplicationController
      include PartnershipSteps

      def new
        authorize provider, :manage_partnerships?
        authorize partnership

        seed_state if wizard.state_store.read.blank?

        return redirect_to(first_step_path) unless wizard.valid_path_to_current_step?

        prepare_step
        render template_for_step
      end

      def update
        authorize provider, :manage_partnerships?
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

        if wizard.current_step_name == :types && wizard.revises_partnership?
          return redirect_to provider_partnership_type_change_path(
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
          flash.now[:alert] = form_errors_message(form)
          return render(template_for_step, status: :unprocessable_content)
        end

        saved = false

        if partnership_ended_since_edit?
          partnership.errors.add(:base, I18n.t("flash_message.alert.check.partnership.ended_while_editing"))
        elsif wizard.revises_partnership?
          saved = revision_saved?(form)
        else
          Partnership.transaction do
            partnership.sync_partnership_types(wizard.selected_partnership_types)
            saved = partnership.update(form.to_partnership_attributes)
            raise ActiveRecord::Rollback unless saved
          end
        end

        unless saved
          prepare_step
          flash.now[:alert] = partnership_save_failure_message(partnership)
          return render(template_for_step, status: :unprocessable_content)
        end

        wizard.clear_state
        redirect_to provider_partnerships_path(provider),
                    flash: { success: I18n.t("flash_message.success.check.partnership.update",
                                             name: partnership.other_partner(provider).operating_name) }
      end

      # The edit is seeded from the partnership as it was. If somebody ends it
      # while the answers are being filled in, saving would write the seeded
      # open-ended duration back onto the ended row and reopen it. A partnership
      # that was already ended when the edit started is left alone: its dates
      # can still be corrected.
      def partnership_ended_since_edit?
        partnership.ended_on? && !seeded_as_ended?
      end

      def seeded_as_ended?
        wizard.state_store.read[:seeded_ended] == true
      end

      def revision_saved?(form)
        revision = partnership.revise_types!(wizard.selected_partnership_types,
                                             academic_years: form.academic_years,
                                             end_date: form.end_date,
                                             start_date: form.start_date)

        revision.present? ||
          partnership.same_day_replacement(wizard.selected_partnership_types).present?
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
        @editing = true

        @academic_years = eligible_academic_years if wizard.current_step_name == :academic_years

        prepare_check_your_answers if wizard.check_your_answers?
      end

      def prepare_check_your_answers
        @form = wizard.partnership_form
        @partnership_types = wizard.selected_partnership_types
        @save_path = wizard.current_step_path
        @save_button_text = "Save partnership"
        @change_paths = {
          types: change_step_path(:types),
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
