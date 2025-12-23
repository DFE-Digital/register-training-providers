module Partnerships
  class FindForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :partner_id, :string

    def self.model_name
      ActiveModel::Name.new(self, nil, "Find")
    end

    def self.i18n_scope
      :activerecord
    end
  end
end
