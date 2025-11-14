module Addresses
  class SelectForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    attribute :selected_address_index, :integer

    validates :selected_address_index, presence: true

    def self.model_name
      ActiveModel::Name.new(self, nil, "Select")
    end

    def self.i18n_scope
      :activerecord
    end
  end
end
