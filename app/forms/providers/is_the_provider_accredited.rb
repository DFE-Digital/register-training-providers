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

    def accreditation_status_options_for_radios(user)
      AccreditationStatusEnum::ACCREDITATION_STATUSES.keys.filter_map do |key|
        next unless ProviderPolicy.new(user, self.class.new(accreditation_status: key)).create?

        SelectOption.new(
          key: key,
          value: I18n.t("forms.providers.is_the_provider_accredited.accreditation_status.#{key}"),
        )
      end
    end

    def single_accreditation_status_for(user)
      options = accreditation_status_options_for_radios(user)

      options.one? ? options.first : nil
    end

    def accreditation_status_question_for(user)
      option = single_accreditation_status_for(user)
      return "Is the provider accredited?" if option.nil?

      if option.key.to_s == AccreditationStatusEnum::ACCREDITED
        "The provider is accredited"
      else
        "The provider is not accredited"
      end
    end

    def new_record?
      true
    end

    alias_method :serializable_hash, :attributes
  end
end
