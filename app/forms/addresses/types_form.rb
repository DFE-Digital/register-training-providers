module Addresses
  class TypesForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :types

    validates :types, presence: true

    def self.model_name
      ActiveModel::Name.new(self, nil, "Types")
    end

    def self.i18n_scope
      :activerecord
    end

    def self.from_address(address)
      new(types: address.types)
    end
  end
end
