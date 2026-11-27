module Providers
  class ProviderChangesController < ApplicationController
    helper_method :provider_changes

    def new
      authorize provider, :update?

      if wizard.valid_path_to_current_step?
        try_restore_pending_existing_provider_changes

        @review = review if wizard.check_your_answers?

        render template_path
      else
        redirect_to wizard.previous_step_path
      end
    end

    def update
      authorize provider, :update?

      return redirect_after_stale_confirmation if stale_confirmation?
      return redirect_to wizard.previous_step_path unless wizard.valid_path_to_current_step?

      if wizard.save_current_step
        wizard.mark_completed if wizard.check_your_answers?

        if wizard.completed?
          save_provider_change

          wizard.clear_state
          remember_confirmation
          redirect_to provider_path(provider), flash: success_flash
        else
          redirect_to wizard.next_step_path
        end
      else
        render template_path
      end
    end

    def history
      authorize provider, :show?

      provider_changes

      render "providers/provider_changes/#{field}/history"
    end

  private

    def save_provider_change
      SaveProviderChangeService.call(
        provider: provider,
        attribute_name: field,
        attributes: wizard.provider_change_attributes,
        creator: current_user
      )
    end

    def stale_confirmation?
      wizard.check_your_answers? && state_store.read.blank? && recently_confirmed?
    end

    def recently_confirmed?
      confirmed_at = session[confirmation_key]

      confirmed_at.present? &&
        Time.zone.at(confirmed_at) > SaveProviderChangeService::IDENTICAL_CONFIRM_REUSE_WINDOW.ago
    end

    def remember_confirmation
      session[confirmation_key] = Time.current.to_i
    end

    def forget_confirmation
      session.delete(confirmation_key)
    end

    def confirmation_key
      :"provider_change_#{provider.id}_#{field}_confirmed_at"
    end

    def redirect_after_stale_confirmation
      forget_confirmation
      wizard.clear_state

      redirect_to provider_path(provider), flash: success_flash
    end

    def success_flash
      { success: I18n.t("flash_message.success.provider_change.#{field}.updated") }
    end

    def try_restore_pending_existing_provider_changes
      if wizard.first_step? && params[:return_to_review].blank?
        provider_change = provider.provider_changes.pending.for_attribute(field).first
        wizard.set_state_store(provider_change) if provider_change.present?
      end
    end

    def provider_changes
      @provider_changes ||= provider.provider_changes.history.for_attribute(field)
    end

    def provider
      @provider ||= Provider.kept.find(params[:provider_id])
    end

    def repository
      @repository ||= DfE::Wizard::Repository::Session.new(
        session: session,
        key: :"provider_change_#{provider.id}_#{field}"
      )
    end

    def state_store
      @state_store ||= ProviderChanges::Registry.state_store_for(field).new(
        repository:
      )
    end

    def wizard
      @wizard ||= ProviderChanges::Registry.wizard_for(field).new(
        provider: provider,
        current_step: current_step,
        current_step_params: params,
        state_store: state_store
      )
    end

    def review
      ProviderChanges::Registry.review_for(field).new(wizard)
    end

    def current_step
      @current_step ||= params[:step].tr("-", "_").to_sym
    end

    def field
      @field ||= params[:field].to_sym
    end

    def template_path
      "providers/provider_changes/#{field}/#{current_step}"
    end
  end
end
