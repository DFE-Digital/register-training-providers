module ProviderChanges
  module Steps
    class EffectiveDateStep
      include DfE::Wizard::Step
      include WizardDateComponents
      include ActiveModel::Validations::Callbacks
      include GovukDateValidation

      has_date_components :effective_on

      before_validation :convert_date_components

      validates_govuk_date :effective_on, required: true, today_or_future: true

      def self.permitted_params
        %i[effective_on] + const_get(:PARAM_CONVERSION).keys
      end
    end
  end
end
