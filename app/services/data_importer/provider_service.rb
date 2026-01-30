module DataImporter
  class ProviderService
    include ServicePattern

    def initialize(row)
      @row = row
    end

    def call
      provider = Provider.find_or_initialize_by(
        code: raw_provider["code"]
      )

      assign_provider_attributes(provider)
      assign_accreditation(provider) if accreditation_status == "accredited"
      assign_address(provider)

      provider.save!(validate: false)

      attach_seed_data(provider)

      provider.save!(validate: false)
    end

  private

    attr_reader :row

    def accreditation_status
      if value("accreditation__number").blank?
        "unaccredited"
      else
        "accredited"

      end
    end

    def assign_provider_attributes(provider)
      provider.legal_name        = raw_provider["legal_name"]
      provider.operating_name    = raw_provider["operating_name"]
      provider.provider_type     = provider_type
      provider.accreditation_status = accreditation_status
      provider.ukprn             = parsed_ukprn
      provider.urn               = raw_provider["urn"]
      provider.academic_years_active = parse_academic_years
    end

    def provider_type
      # if raw_provider["provider_type"] == "scitt" && raw_provider["accreditation_status"] == "unaccredited"
      #   "school"
      # else
      raw_provider["provider_type"]
      # end
    end

    def assign_accreditation(provider)
      number = value("accreditation__number")
      return if number.blank?

      provider.accreditations.find_or_initialize_by(number:) do |acc|
        acc.start_date = parse_date(raw_accreditation["start_date"])
        acc.end_date   = parse_date(raw_accreditation["end_date"])
      end
    end

    def assign_address(provider)
      postcode = value("address__postcode")
      has_clean_address = value("address__found") == "true" && postcode.present?

      return unless has_clean_address

      provider.addresses.find_or_initialize_by(postcode:) do |address|
        address.address_line_1 = raw_address["address_line_1"]
        address.address_line_2 = raw_address["address_line_2"]
        address.address_line_3 = raw_address["address_line_3"]
        address.county = raw_address["county"]
        address.latitude = raw_address["latitude"]
        address.longitude = raw_address["longitude"]

        address.town_or_city = raw_address["town_or_city"]
        address.uprn = raw_address["uprn"]
      end
    end

    def attach_seed_data(provider)
      provider.valid?

      provider.errors.add(:ukprn, "Not found") if ukprn_not_found?

      provider.seed_data_with_issues = provider.errors.any?

      provider.seed_data_notes = {
        row_imported: row_imported,
        errors: provider.errors.to_hash,
        saved_as: {
          provider_id: provider.id,
          accreditation_id: accreditation_id_for(provider),
          address_id: address_id_for(provider),
        }
      }
    end

    def address_id_for(provider)
      postcode = value("address__postcode")
      has_clean_address = value("address__found") == "true" && postcode.present?

      return unless has_clean_address

      Address.find_by(provider:, postcode:)&.id
    end

    def accreditation_id_for(provider)
      number = value("accreditation__number")

      return nil if number.blank?

      Accreditation.find_by(provider:, number:)&.id
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
      return [v] if v.is_a?(Integer)

      v.split(",").map(&:to_i)
    end

    def parsed_ukprn
      return "00000000" if ukprn_not_found?

      raw_provider["ukprn"]
    end

    def ukprn_not_found?
      raw_provider["ukprn"].blank? || raw_provider["ukprn"].to_s.downcase == "not found"
    end
  end
end
