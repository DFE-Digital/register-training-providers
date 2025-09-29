class PostcodeValidator < ActiveModel::EachValidator
  # UK postcode regex pattern
  POSTCODE_PATTERN = /\A[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}\z/i

  def validate_each(record, attribute, value)
    return if value.blank?

    unless value.match?(POSTCODE_PATTERN)
      record.errors.add(attribute, :invalid_postcode_format)
    end
  end
end
