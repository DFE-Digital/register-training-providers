class UkTelephoneNumberFormatValidator
  # rubocop:disable Layout/LineLength
  UK_TELEPHONE_NUMBER_REGEX = /^(?:(?:\(?(?:0(?:0|11)\)?[\s-]?\(?|\+)44\)?[\s-]?(?:\(?0\)?[\s-]?)?)|(?:\(?0))(?:(?:\d{5}\)?[\s-]?\d{4,5})|(?:\d{4}\)?[\s-]?(?:\d{5}|\d{3}[\s-]?\d{3}))|(?:\d{3}\)?[\s-]?\d{3}[\s-]?\d{3,4})|(?:\d{2}\)?[\s-]?\d{4}[\s-]?\d{4}))(?:[\s-]?(?:x|ext\.?|\#)\d{3,4})?$/
  # rubocop:enable Layout/LineLength

  def initialize(record)
    @record = record
    @telephone_number = record.telephone_number
  end

  def validate
    return unless telephone_number

    record.errors.add(:telephone_number, error_message) unless valid?
  end

private

  attr_reader :record, :telephone_number

  def valid?
    matches_regex?
  end

  def matches_regex?
    UK_TELEPHONE_NUMBER_REGEX.match?(telephone_number)
  end

  def error_message
    I18n.t("activemodel.errors.validators.uk_telephone_number.invalid")
  end
end
