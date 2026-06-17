module Providers
  class FirstBecomeActiveForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    include GovukDateValidation
    include GovukDateComponents

    attribute :onboarded_at, :date

    before_validation :convert_date_components

    def self.model_name
      ActiveModel::Name.new(self, nil, "Provider")
    end

    def self.i18n_scope
      :activerecord
    end

    def self.additional_params
      [["onboarded_at", "onboarded_at"]]
    end

    has_date_components_with_choice :first_active_at_date

    validates :first_active_at_date_choice, presence: true

    validates :first_active_at_date, presence: true, if: -> { first_active_at_date_choice == "other" }

    def predefined_dates
      {
        "same" => onboarded_at
      }
    end

    def first_active_at
      resolve_date_from_choice(:first_active_at_date)
    end
  end
end
