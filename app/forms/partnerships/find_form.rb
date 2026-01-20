module Partnerships
  class FindForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations::Callbacks

    attribute :partner_id, :string
    attribute :partner_id_raw, :string
    attribute :provider_accredited, :boolean

    validate :partner_id_present
    validate :partner_must_exist, if: -> { partner_id.present? }

    def self.model_name
      ActiveModel::Name.new(self, nil, "Find")
    end

    def self.i18n_scope
      :activerecord
    end

  private

    def partner_id_present
      return if partner_id.present?

      error_key = provider_accredited ? :blank_training_partner : :blank_accredited_provider
      errors.add(:partner_id, error_key)
    end

    def partner_must_exist
      return if Provider.exists?(partner_id)

      errors.add(:partner_id, :invalid)
    end
  end
end
