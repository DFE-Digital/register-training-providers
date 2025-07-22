module ProviderTypeEnum
  extend ActiveSupport::Concern

  PROVIDER_TYPES = %i[hei scitt school other].index_with(&:to_s).freeze

  ACCREDITED_PROVIDER_TYPES = PROVIDER_TYPES.slice(:hei, :scitt, :other).freeze
  UNACCREDITED_PROVIDER_TYPES = PROVIDER_TYPES.slice(:hei, :school, :other).freeze

  included do
    enum :provider_type, PROVIDER_TYPES
  end

  def provider_type_label
    return "Not entered" if provider_type.blank?

    I18n.t("providers.provider_types.#{provider_type}")
  end
end
