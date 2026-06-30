module Providers
  class OnboardingForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include GovukDateValidation
    include GovukDateComponents

    has_date_components_with_choice :onboarded_at_date

    validates :onboarded_at_date_choice, presence: true

    validates :onboarded_at_date, presence: true, if: -> { onboarded_at_date_choice == "other" }

    before_validation :convert_date_components

    def self.model_name
      ActiveModel::Name.new(self, nil, "Provider")
    end

    def self.i18n_scope
      :activerecord
    end

    def predefined_dates
      {
        "today" => Time.zone.today,
        "yesterday" => Time.zone.yesterday,
      }
    end

    def onboarded_at
      resolve_date_from_choice(:onboarded_at_date)
    end
  end
end
