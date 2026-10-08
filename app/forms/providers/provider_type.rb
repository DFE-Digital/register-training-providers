module Providers
  class ProviderType
    include ActiveModel::Model
    include ActiveModel::Attributes
    include AccreditationStatusValidator

    attribute :provider_type, :string

    attribute :accreditation_status, :string

    validates :provider_type, presence: true,
                              inclusion: { in: ProviderTypeEnum::PROVIDER_TYPES.values }

    def self.model_name
      ActiveModel::Name.new(self, nil, "Provider")
    end

    def self.i18n_scope
      :activerecord
    end

    def provider_type_options_for_radios
      ProviderTypeEnum::PROVIDER_TYPES.keys.map do |key|
        SelectOption.new(
          key: key,
          value: I18n.t("providers.provider_types.#{key}"),
        )
      end
    end

    alias_method :serializable_hash, :attributes

    def accredited?
      accreditation_status == AccreditationStatusEnum::ACCREDITED
    end

    def new_record?
      true
    end
  end
end
