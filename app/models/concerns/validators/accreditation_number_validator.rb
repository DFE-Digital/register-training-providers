class AccreditationNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    provider_type = get_provider_type(record)

    unless valid_format?(value, provider_type)
      record.errors.add(attribute, error_key(provider_type))
    end
  end

private

  def get_provider_type(record)
    # First check if provider_type is directly available on the record
    if record.respond_to?(:provider_type) && record.provider_type.present?
      record.provider_type
    elsif record.respond_to?(:provider_id) && record.provider_id.present?
      # Form object will have provider_id, need to look up provider
      begin
        Provider.find(record.provider_id).provider_type
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
  end

  def valid_format?(value, provider_type)
    return false unless value.match?(/\A\d{4}\z/) # Must be 4 digits

    case provider_type
    when "hei"
      value.start_with?("1")
    when "scitt", "school"
      value.start_with?("5")
    else
      value.match?(/\A[15]\d{3}\z/) # Either 1 or 5 for unknown types
    end
  end

  def error_key(provider_type)
    case provider_type
    when "hei"
      :invalid_format_hei
    when "scitt", "school"
      :invalid_format_scitt
    else
      :invalid_format_generic
    end
  end
end
