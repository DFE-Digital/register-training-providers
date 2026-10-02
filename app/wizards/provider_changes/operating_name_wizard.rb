module ProviderChanges
  class OperatingNameWizard < BaseWizard
    def provider_change_attributes
      state = state_store.read.with_indifferent_access

      {
        attribute_name: "operating_name",
        effective_on: state["effective_on"],
        value: state["operating_name"].presence || ""
      }
    end

  private

    def field
      "operating_name"
    end

    def steps
      {
        effective_date: ProviderChanges::Steps::EffectiveDateStep,
        new_operating_name: ProviderChanges::Steps::OperatingNameStep,
        check_your_answers: ProviderChanges::Steps::CheckYourAnswersStep
      }
    end
  end
end
