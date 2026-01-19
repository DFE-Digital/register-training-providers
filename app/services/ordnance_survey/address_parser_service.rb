module OrdnanceSurvey
  class AddressParserService
    include ServicePattern

    def initialize(dpa)
      @dpa = dpa
    end

    def call
      line1 = []
      line2 = []
      line3 = []

      line1 << dpa["SUB_BUILDING_NAME"].titleize if present?(dpa["SUB_BUILDING_NAME"])
      line1 << dpa["BUILDING_NAME"].titleize if present?(dpa["BUILDING_NAME"])

      address_part_2 = []
      address_part_2 << dpa["BUILDING_NUMBER"].titleize if present?(dpa["BUILDING_NUMBER"])
      address_part_2 << dpa["DEPENDENT_THOROUGHFARE_NAME"].titleize if present?(dpa["DEPENDENT_THOROUGHFARE_NAME"])
      address_part_2 << dpa["THOROUGHFARE_NAME"].titleize if present?(dpa["THOROUGHFARE_NAME"])

      if line1.empty?
        line1 = address_part_2
      else
        line2 = address_part_2
      end

      address_part_3 = []
      address_part_3 << dpa["DOUBLE_DEPENDENT_LOCALITY"].titleize if present?(dpa["DOUBLE_DEPENDENT_LOCALITY"])
      address_part_3 << dpa["DEPENDENT_LOCALITY"].titleize if present?(dpa["DEPENDENT_LOCALITY"])

      if line2.empty?
        line2 = address_part_3
      else
        line3 = address_part_3
      end

      {
        uprn: dpa["UPRN"],
        organisation_name: dpa["ORGANISATION_NAME"].to_s.titleize,
        address_line_1: join(line1),
        address_line_2: join(line2),
        address_line_3: join(line3),
        town_or_city: dpa["POST_TOWN"].to_s.titleize,
        county: nil, # NOTE: OS Places does not provide county data
        postcode: dpa["POSTCODE"].to_s,
        latitude: dpa["LAT"],
        longitude: dpa["LNG"],
      }
    end

  private

    attr_reader :dpa

    def present?(value)
      value.respond_to?(:strip) ? !value.strip.empty? : value.present?
    end

    def join(parts)
      parts.compact.join(", ")
    end
  end
end
