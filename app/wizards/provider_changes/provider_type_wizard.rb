module ProviderChanges
  class ProviderTypeWizard < BaseWizard
    def provider_change_attributes
      state = state_store.read.with_indifferent_access

      {
        attribute_name: "provider_type",
        effective_on: state["effective_on"],
        value: state["provider_type"].presence || ""
      }
    end

  private

    def field
      "provider_type"
    end

    def steps
      {
        effective_date: ProviderChanges::Steps::EffectiveDateStep,
        new_provider_type: ProviderChanges::Steps::ProviderTypeStep,
        check_your_answers: ProviderChanges::Steps::CheckYourAnswersStep
      }
    end
  end
end
