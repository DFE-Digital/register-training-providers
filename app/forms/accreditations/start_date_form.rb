module Accreditations
  class StartDateForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include GovukDateValidation
    include GovukDateComponents

    attribute :provider_id, :string
    has_date_components :start_date

    validates :start_date, presence: true

    def self.from_start_date(start_date)
      form = new

      new(form.extract_date_components_from(start_date))
    end

    def self.i18n_scope
      :activerecord
    end

    def self.model_name
      ActiveModel::Name.new(self, nil, "Accreditation")
    end

    def initialize(attributes = {})
      super
      convert_date_components if start_date.blank?
    end

    def provider
      return Provider.new if provider_id.blank?

      Provider.find(provider_id)
    end
  end
end
