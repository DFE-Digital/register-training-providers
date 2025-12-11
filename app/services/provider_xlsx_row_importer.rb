class ProviderXlsxRowImporter
  include ServicePattern

  def initialize(row)
    @row = row
  end

  def call
    provider = Provider.find_or_initialize_by(
      code: raw_provider["code"]
    )

    assign_provider_attributes(provider)
    assign_accreditation(provider)
    attach_seed_data(provider)

    provider.seed_data_with_issues = provider.errors.any?

    provider.save!(validate: false)
  end

private

  attr_reader :row

  def assign_provider_attributes(provider)
    provider.legal_name        = raw_provider["legal_name"]
    provider.operating_name    = raw_provider["operating_name"]
    provider.provider_type     = raw_provider["provider_type"]&.downcase
    provider.accreditation_status = raw_provider["accreditation_status"]
    provider.ukprn             = parsed_ukprn
    provider.urn               = raw_provider["urn"]

    provider.valid?
    provider.errors.add(:ukprn, "Not found") if ukprn_not_found?
  end

  def assign_accreditation(provider)
    number = value("accreditation__number")
    return if number.blank?

    provider.accreditations.find_or_initialize_by(number:) do |acc|
      acc.start_date = parse_date(raw_accreditation["start_date"])
      acc.end_date   = parse_date(raw_accreditation["end_date"])
    end
  end

  def attach_seed_data(provider)
    provider.seed_data_notes = {
      row_imported: row_imported,
      errors: provider.errors.to_hash
    }
  end

  def raw_provider
    extract("provider")
  end

  def raw_accreditation
    extract("accreditation")
  end

  def raw_address
    extract("address")
  end

  def extract(prefix)
    @extracted ||= {}

    @extracted[prefix] ||= row
      .select { |k, _| k.start_with?("#{prefix}__") }
      .transform_keys { |k| k.sub("#{prefix}__", "") }
  end

  def row_imported
    {
      raw: row,
      provider: raw_provider,
      accreditation: raw_accreditation,
      address: raw_address
    }
  end

  def value(key)
    row[key]
  end

  def parse_date(raw_date)
    raw_date.is_a?(Date) ? raw_date : Date.parse(raw_date.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_academic_years
    v = raw_provider["academic_years_active"]
    return [] if v.blank?

    v.is_a?(Array) ? v : v.to_s.split(",").map(&:strip)
  end

  def parsed_ukprn
    return "00000000" if ukprn_not_found?

    raw_provider["ukprn"]
  end

  def ukprn_not_found?
    raw_provider["ukprn"].blank? || raw_provider["ukprn"].to_s.downcase == "not found"
  end
end
