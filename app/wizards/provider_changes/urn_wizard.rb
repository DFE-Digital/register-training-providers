module ProviderChanges
  class UrnWizard < BaseWizard
    def provider_change_attributes
      state = state_store.read.with_indifferent_access

      {
        attribute_name: "urn",
        effective_on: state["effective_on"],
        value: state["urn"].presence || ""
      }
    end

  private

    def field
      "urn"
    end

    def steps
      {
        effective_date: ProviderChanges::Steps::EffectiveDateStep,
        new_urn: ProviderChanges::Steps::UrnStep,
        check_your_answers: ProviderChanges::Steps::CheckYourAnswersStep
      }
    end
  end
end
