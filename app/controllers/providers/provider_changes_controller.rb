module Providers
  class ProviderChangesController < ApplicationController
    def new
      authorize provider, :update?

      if wizard.current_step_name == :check_your_answers
        @review = ProviderChanges::Presenters::CodeReview.new(@wizard)
      end

      render template_path
    end

    def update
      authorize provider, :update?

      if wizard.save_current_step
        if wizard.current_step_name == :check_your_answers
          wizard.mark_completed
        end

        if wizard.completed?
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

  private

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
      @current_step ||= params[:step]&.to_sym || :effective_academic_year
    end

    def field
      @field ||= params[:field].to_sym
    end

    def template_path
      "providers/provider_changes/#{field}/#{current_step}"
    end
  end
end
