module Providers
  module MarkAsInactive
    class DateForm
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations::Callbacks

      include GovukDateValidation
      include GovukDateComponents

      has_date_components :start_date

      before_validation :convert_date_components

      validates :start_date, presence: true
    end
  end
end
