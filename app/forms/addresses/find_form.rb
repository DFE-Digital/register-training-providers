module Addresses
  class FindForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :postcode, :string
    attribute :building_name_or_number, :string

    before_validation :normalize_postcode

    validates :postcode, presence: true, postcode: true
    validates :building_name_or_number, length: { maximum: 255 }, allow_blank: true

    def self.model_name
      ActiveModel::Name.new(self, nil, "Find")
    end

    def self.i18n_scope
      :activerecord
    end

  private

    def normalize_postcode
      return if postcode.blank?

      postcode.upcase!
      postcode.strip!
    end
  end
end
