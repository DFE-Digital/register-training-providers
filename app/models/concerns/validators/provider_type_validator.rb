class ProviderTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    allowed_types = if record.accredited?
                      ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.values
                    else
                      ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.values
                    end

    unless allowed_types.include?(value)
      record.errors.add(attribute, :inclusion, value:)
    end
  end
end
