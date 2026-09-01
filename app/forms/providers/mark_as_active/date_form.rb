module Providers
  module MarkAsActive
    class DateForm
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations::Callbacks

      include GovukDateValidation
      include GovukDateComponents

      has_date_components :end_date

      attribute :start_date

      before_validation :convert_date_components

      validates :end_date, presence: true

      validates :end_date, comparison: { greater_than: :start_date }

      def self.i18n_scope
        :activerecord
      end
    end
  end
end
