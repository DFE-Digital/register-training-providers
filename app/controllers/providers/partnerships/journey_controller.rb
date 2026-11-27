module Providers
  module Partnerships
    class JourneyController < ApplicationController
      include PartnershipSteps

      PartnerOption = Struct.new(:name, :value, :hint, :search_text)

      def new
        authorize provider, :manage_partnerships?

        wizard.clear_state if current_step.nil?

        return unless valid_journey_path?

        redirect_to(step_path(:find_partner)) and return if answers_incomplete?

        prepare_step
        render template_for_step
      end

      def update
        authorize provider, :manage_partnerships?

        return unless valid_journey_path?

        redirect_to(step_path(:find_partner)) and return if answers_incomplete?

        unless wizard.save_current_step
          prepare_step
          return render(template_for_step, status: :unprocessable_content)
        end

        return save_partnership if wizard.check_your_answers?

        redirect_to wizard.next_step_path(return_to_review: params[:return_to_review])
      end

    private

      def valid_journey_path?
        return true if wizard.valid_path_to_current_step?

        if wizard.state_store.read.blank?
          redirect_to(step_path(:find_partner))
        else
          flash[:alert] = I18n.t("flash_message.alert.check.partnership.types_unavailable")
          redirect_to(step_path(:types))
        end

        false
      end

      def answers_incomplete?
        return false unless wizard.check_your_answers?

        wizard.partnership_form.invalid?
      end

      def save_partnership
        form = wizard.partnership_form
        partnership = provider.partnerships.build(form.to_partnership_attributes)
        partnership.apply_partnership_types(wizard.selected_partnership_types)
        authorize partnership

        unless partnership.save
          @partnership = partnership
          prepare_step
          flash.now[:alert] = partnership_save_failure_message(partnership)
          return render(template_for_step, status: :unprocessable_content)
        end

        wizard.clear_state
        redirect_to provider_partnerships_path(provider),
                    flash: { success: I18n.t("flash_message.success.check.partnership.add") }
      end

      def prepare_step
        @wizard = wizard
        @form = wizard.current_step
        @form_url = wizard.current_step_path(return_to_review: params[:return_to_review])
        @form_method = :post
        @back_path = wizard.previous_step_path(fallback: provider_partnerships_path(provider))
        @cancel_path = provider_partnerships_path(provider)
        @page_caption = "Add partnership - #{provider.operating_name}"
        @page_subtitle = provider.operating_name.to_s
        @page_title = page_title_for_step
        @provider_accredited = provider.accredited?

        @partners = load_eligible_partners if wizard.current_step_name == :find_partner
        @academic_years = eligible_academic_years if wizard.current_step_name == :academic_years

        prepare_check_your_answers if wizard.check_your_answers?
      end

      def prepare_check_your_answers
        @form = wizard.partnership_form
        @partnership_types = wizard.selected_partnership_types
        @save_path = wizard.current_step_path
        @save_button_text = "Save partnership"
        @change_paths = {
          partner: change_step_path(:find_partner),
          types: change_step_path(:types),
          dates: change_step_path(:dates),
          academic_years: change_step_path(:academic_years)
        }
      end

      def step_path(step)
        provider_partnership_step_path(provider, step: step.to_s.tr("_", "-"))
      end

      def change_step_path(step)
        provider_partnership_step_path(
          provider,
          step: step.to_s.tr("_", "-"),
          return_to_review: "true"
        )
      end

      def page_title_for_step
        return partner_step_title if wizard.current_step_name == :find_partner

        super
      end

      def partner_step_title
        if provider.accredited?
          "Enter training partner name, code, UKPRN or URN"
        else
          "Enter accredited provider name, code, UKPRN or URN"
        end
      end

      def load_eligible_partners
        wizard.eligible_partners.order(:operating_name).map do |partner|
          PartnerOption.new(
            name: partner.operating_name,
            value: partner.id,
            hint: partner_hint(partner),
            search_text: partner_search_text(partner)
          )
        end
      end

      def partner_hint(provider_record)
        parts = ["Provider code: #{provider_record.code}", "UKPRN: #{provider_record.ukprn}"]
        parts << "URN: #{provider_record.urn}" if provider_record.urn.present?
        parts.join(", ")
      end

      def partner_search_text(provider_record)
        parts = [provider_record.operating_name, provider_record.code, provider_record.ukprn]
        parts << provider_record.urn if provider_record.urn.present?
        parts.join(" | ")
      end

      def provider
        @provider ||= Provider.kept.find(params.expect(:provider_id))
      end

      def repository
        @repository ||= DfE::Wizard::Repository::Session.new(
          session: session,
          key: :"partnership_add_#{provider.id}"
        )
      end

      def state_store
        @state_store ||= ::Partnerships::StateStores::PartnershipStore.new(repository:)
      end

      def wizard
        @wizard ||= ::Partnerships::AddWizard.new(
          provider: provider,
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
