module OrdnanceSurvey
  class AddressLookupService
    include ServicePattern

    BASE_URL = "https://api.os.uk/search/places/v1".freeze

    def initialize(postcode:, building_name_or_number: nil)
      @postcode = postcode
      @building_name_or_number = building_name_or_number
    end

    def call
      response = fetch_addresses
      return [] unless response

      addresses = parse_addresses(response)
      filter_by_building_name_or_number(addresses)
    end

  private

    attr_reader :postcode, :building_name_or_number

    def fetch_addresses
      uri = build_postcode_uri
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("OS Places API error: #{e.message}")
      nil
    end

    def build_postcode_uri
      params = {
        postcode: postcode,
        key: api_key,
        maxresults: 100
      }
      URI("#{BASE_URL}/postcode?#{URI.encode_www_form(params)}")
    end

    def parse_addresses(response)
      results = response["results"] || []

      results.filter_map do |result|
        dpa = result["DPA"]
        next unless dpa

        {
          address_line_1: format_address_line(build_address_line_1(dpa)),
          address_line_2: format_address_line(dpa["DEPENDENT_LOCALITY"]),
          town_or_city: format_address_line(dpa["POST_TOWN"]),
          county: format_address_line(dpa["COUNTY"]),
          postcode: dpa["POSTCODE"],
          latitude: dpa["LATITUDE"],
          longitude: dpa["LONGITUDE"]
        }
      end
    end

    def filter_by_building_name_or_number(addresses)
      return addresses if building_name_or_number.blank?

      search_term = building_name_or_number.downcase.strip

      addresses.select do |address|
        address[:address_line_1].downcase.include?(search_term)
      end
    end

    def build_address_line_1(dpa)
      parts = [
        dpa["ORGANISATION_NAME"],
        dpa["BUILDING_NAME"],
        dpa["BUILDING_NUMBER"],
        dpa["THOROUGHFARE_NAME"]
      ].compact

      parts.join(", ").presence || dpa["ADDRESS"]
    end

    def format_address_line(text)
      return nil if text.blank?

      text.titleize
    end

    def api_key
      Env.ordnance_survey_api_key
    end
  end
end
