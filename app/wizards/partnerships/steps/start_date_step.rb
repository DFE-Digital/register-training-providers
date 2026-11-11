module Partnerships
  module Steps
    class StartDateStep
      include DfE::Wizard::Step
      include WizardDateComponents
      include GovukDateValidation
      include ActiveModel::Validations::Callbacks

      has_date_components :start_date

      attribute :start_today, :string

      before_validation :resolve_start_date

      validates :start_today, inclusion: { in: %w[true false] }
      validates_govuk_date :start_date, required: false, human_name: "date the partnership started"
      validate :start_date_must_be_present

      def self.permitted_params
        %i[start_today start_date] + const_get(:PARAM_CONVERSION).keys
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Partnerships::StartDateStep")
      end

      def self.i18n_scope
        :activerecord
      end

    private

      def resolve_start_date
        if start_today == "true"
          self.start_date = Time.zone.today
          self.start_date_day = start_date.day
          self.start_date_month = start_date.month
          self.start_date_year = start_date.year
        else
          convert_date_components
        end
      end

      def start_date_must_be_present
        return if start_today == "true"
        return if start_date.present?

        errors.add(:start_date, :blank)
      end
    end
  end
end
