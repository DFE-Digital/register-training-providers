class PostcodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    unless UKPostcode.parse(value).valid?
      record.errors.add(attribute, :invalid_postcode_format)
    end
  end
end
