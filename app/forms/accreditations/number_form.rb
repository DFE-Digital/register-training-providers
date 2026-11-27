module Accreditations
  class NumberForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :number, :string
    attribute :provider_id, :string
    attribute :provider_type, :string

    validates :number, presence: true, accreditation_number: true

    def self.model_name
      ActiveModel::Name.new(self, nil, "Accreditation")
    end

    def provider
      return Provider.new if provider_id.blank?

      Provider.find(provider_id)
    end
  end
end
