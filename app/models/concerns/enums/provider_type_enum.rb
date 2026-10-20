module ProviderTypeEnum
  extend ActiveSupport::Concern

  PROVIDER_TYPES = %i[hei scitt school other].index_with(&:to_s).freeze

  def self.label_for(value)
    return "Not entered" if value.blank?

    I18n.t("providers.provider_types.#{value}", default: value.to_s.humanize)
  end

  included do
    enum :provider_type, PROVIDER_TYPES
  end

  def provider_type_label
    ProviderTypeEnum.label_for(provider_type)
  end
end
