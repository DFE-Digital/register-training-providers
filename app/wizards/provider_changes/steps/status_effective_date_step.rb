module ProviderChanges
  module Steps
    class StatusEffectiveDateStep
      include DfE::Wizard::Step
      include WizardDateComponents
      include ActiveModel::Validations::Callbacks
      include GovukDateValidation

      has_date_components :effective_on

      before_validation :convert_date_components

      validates_govuk_date :effective_on,
                           required: true,
                           human_name: "date that the status change applies from"

      validate :effective_date_not_before_the_provider_existed, unless: -> { errors.key?(:effective_on) }
      validate :effective_date_within_an_existing_period, unless: -> { errors.key?(:effective_on) }

      def self.permitted_params
        %i[effective_on] + const_get(:PARAM_CONVERSION).keys
      end

    private

      def effective_date_within_an_existing_period
        return if effective_on.blank?
        return if ProviderStatusEnum.period_conflicting_with_date(wizard.provider.inactive_periods, effective_on).blank?

        errors.add(:effective_on, :within_existing_period)
      end

      def effective_date_not_before_the_provider_existed
        return if effective_on.blank?

        earliest_date = ProviderStatusEnum.earliest_valid_date(wizard.provider)
        return if earliest_date.blank? || effective_on >= earliest_date

        errors.add(:effective_on, :before_the_provider_existed)
      end
    end
  end
end
