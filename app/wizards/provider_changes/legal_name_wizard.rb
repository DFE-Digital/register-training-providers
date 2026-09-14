module ProviderChanges
  class LegalNameWizard < BaseWizard
    def provider_change_attributes
      state = state_store.read.with_indifferent_access

      {
        attribute_name: "legal_name",
        effective_on: state["effective_on"],
        value: state["legal_name"]
      }
    end

  private

    def field
      "legal_name"
    end

    def steps
      {
        effective_date: ProviderChanges::Steps::EffectiveDateStep,
        new_legal_name: ProviderChanges::Steps::LegalNameStep,
        check_your_answers: ProviderChanges::Steps::CheckYourAnswersStep
      }
    end
  end
end
