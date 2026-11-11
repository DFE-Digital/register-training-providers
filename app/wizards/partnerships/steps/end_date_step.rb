module Partnerships
  module Steps
    class EndDateStep
      include DfE::Wizard::Step
      include WizardDateComponents
      include GovukDateValidation
      include ActiveModel::Validations::Callbacks

      has_date_components :end_date

      before_validation :convert_date_components

      validates_govuk_date :end_date, required: true, human_name: "date the partnership ended"
      validate :end_date_must_be_after_start_date

      def self.permitted_params
        %i[end_date] + const_get(:PARAM_CONVERSION).keys
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Partnerships::EndDateStep")
      end

      def self.i18n_scope
        :activerecord
      end

    private

      def start_date
        return if wizard.blank?

        wizard.state_store.read.with_indifferent_access[:start_date]
      end

      def end_date_must_be_after_start_date
        return if end_date.blank?

        return if start_date.blank?
        return if end_date > start_date

        errors.add(:end_date, "End date must be after #{start_date.to_fs(:govuk)}")
      end
    end
  end
end
