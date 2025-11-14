module Providers
  class IsTheProviderAccredited
    include ActiveModel::Model
    include ActiveModel::Attributes
    include AccreditationStatusValidator

    attribute :accreditation_status, :string

    def self.model_name
      ActiveModel::Name.new(self, nil, "Provider")
    end

    def self.i18n_scope
      :activerecord
    end

    def accreditation_status_options_for_radios
      AccreditationStatusEnum::ACCREDITATION_STATUSES.keys.map do |key|
        SelectOption.new(
          key: key,
          value: I18n.t("forms.providers.is_the_provider_accredited.accreditation_status.#{key}"),
        )
      end
    end

    alias_method :serializable_hash, :attributes
  end
end
