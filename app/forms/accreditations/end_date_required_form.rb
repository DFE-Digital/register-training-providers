module Accreditations
  class EndDateRequiredForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :end_date_required

    validates :end_date_required, presence: true
    validates :end_date_required, inclusion: ["true", "false"]

    def end_date_required?
      end_date_required == "true"
    end
  end
end
