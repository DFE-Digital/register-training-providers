module Accreditations
  class EndDateForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include GovukDateValidation
    include GovukDateComponents

    has_date_components :end_date

    validates :end_date, presence: true

    def self.model_name
      ActiveModel::Name.new(self, nil, "Accreditation")
    end

    def self.from_end_date(end_date)
      form = new

      new(form.extract_date_components_from(end_date))
    end

    def self.i18n_scope
      :activerecord
    end

    def initialize(attributes = {})
      super
      convert_date_components if end_date.blank?
    end
  end
end
