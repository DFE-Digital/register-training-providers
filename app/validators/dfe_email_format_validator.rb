class DfeEmailFormatValidator < EmailFormatValidator
  DFE_HOSTNAME = "education.gov.uk"

  def initialize(record)
    super
  end

  def validate
    return unless email

    record.errors.add(:email, error_message) unless valid?
  end

private

  def hostname_valid?
    hostname_length_valid? &&
      parts_length_valid? &&
      parts_match_regex? &&
      parts.count == 3 ? hostname == DFE_HOSTNAME : hostname.ends_with?(DFE_HOSTNAME)
  end

  def error_message
    I18n.t("activemodel.errors.validators.dfe_email.invalid")
  end
end
