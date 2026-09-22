module ProviderChanges
  class UkprnWizard < BaseWizard
    def provider_change_attributes
      state = state_store.read.with_indifferent_access

      {
        attribute_name: "ukprn",
        effective_on: state["effective_on"],
        value: state["ukprn"].presence || ""
      }
    end

  private

    def field
      "ukprn"
    end

    def steps
      {
        effective_date: ProviderChanges::Steps::EffectiveDateStep,
        new_ukprn: ProviderChanges::Steps::UkprnStep,
        check_your_answers: ProviderChanges::Steps::CheckYourAnswersStep
      }
    end
  end
end
