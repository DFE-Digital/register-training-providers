module Partnerships
  class DatesForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks
    include GovukDateValidation
    include GovukDateComponents

    has_date_components :start_date, :end_date

    validates :start_date, presence: true

    def self.from_dates(dates)
      form = new

      new(form.extract_date_components_from(dates))
    end

    def self.i18n_scope
      :activerecord
    end

    def initialize(attributes = {})
      super
      convert_date_components unless start_date.present? || end_date.present?
    end
  end
end
