class ProviderTypeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless ProviderTypeEnum::PROVIDER_TYPES.value?(value)
      record.errors.add(attribute, :inclusion, value:)
    end
  end
end
