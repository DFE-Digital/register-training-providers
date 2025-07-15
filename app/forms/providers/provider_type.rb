module Providers
  class ProviderType
    include ActiveModel::Model
    include ActiveModel::Attributes
    include AccreditationStatusValidator
    include SaveAsTemporary

    attribute :provider_type, :string

    attribute :accreditation_status, :string

    validates :provider_type, presence: true, provider_type: true

    def self.model_name
      ActiveModel::Name.new(self, nil, "Provider")
    end

    def self.i18n_scope
      :activerecord
    end

    def provider_type_options_for_radios
      provider_types.keys.map do |key|
        SelectOption.new(
          key: key,
          value: I18n.t("forms.providers.provider_type.provider_type.#{key}"),
        )
      end
    end

    alias_method :serializable_hash, :attributes

    def accredited?
      accreditation_status == AccreditationStatusEnum::ACCREDITED
    end

  private

    def provider_types
      if accredited?
        ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES
      else
        ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES
      end
    end
  end
end
