module Providers
  class ProviderChangesController < ApplicationController
    helper_method :provider_changes

    def new
      authorize provider, :update?

      if wizard.valid_path_to_current_step?
        try_restore_pending_existing_provider_changes

        @review = ProviderChanges::Presenters::CodeReview.new(wizard) if wizard.check_your_answers?

        render template_path
      else
        redirect_to wizard.previous_step_path
      end
    end

    def update
      authorize provider, :update?

      if wizard.save_current_step
        wizard.mark_completed if wizard.check_your_answers?

        if wizard.completed?
          save_provider_change

          wizard.clear_state
          redirect_to provider_path(provider),
                      flash: { success: I18n.t("flash_message.success.provider_change.#{field}.updated") }
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
      @state_store ||= ProviderChanges::StateStores::CodeStore.new(
        repository:
      )
    end

    def wizard
      @wizard ||= ProviderChanges::CodeWizard.new(
        provider: provider,
        current_step: current_step,
        current_step_params: params,
        state_store: state_store
      )
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
