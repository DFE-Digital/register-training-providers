module Addresses
  class GeocodeService
    include ServicePattern

    BASE_URL = "https://api.os.uk/search/places/v1"

    def initialize(postcode:)
      @postcode = postcode
    end

    def call
      response = fetch_coordinates
      return default_result unless response

      extract_coordinates(response)
    end

  private

    attr_reader :postcode

    def fetch_coordinates
      uri = build_uri
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue StandardError => e
      Rails.logger.error("OS Places API geocoding error: #{e.message}")
      nil
    end

    def build_uri
      params = {
        postcode: postcode,
        key: api_key,
        maxresults: 1
      }
      URI("#{BASE_URL}/postcode?#{URI.encode_www_form(params)}")
    end

    def extract_coordinates(response)
      first_result = response.dig("results", 0)
      return default_result unless first_result

      dpa = first_result["DPA"]
      return default_result unless dpa

      {
        latitude: dpa["LATITUDE"],
        longitude: dpa["LONGITUDE"]
      }
    end

    def default_result
      { latitude: nil, longitude: nil }
    end

    def api_key
      ENV.fetch("ORDNANCE_SURVEY_API_KEY")
    end
  end
end

