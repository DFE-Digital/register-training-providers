module Partnerships
  module Steps
    class DatesStep
      include DfE::Wizard::Step
      include WizardDateComponents
      include GovukDateValidation
      include ActiveModel::Validations::Callbacks

      has_date_components :start_date, :end_date

      before_validation :convert_date_components

      validates :start_date, presence: true

      def self.permitted_params
        %i[start_date end_date] + const_get(:PARAM_CONVERSION).keys
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Partnerships::DatesStep")
      end

      def self.i18n_scope
        :activerecord
      end
    end
  end
end
