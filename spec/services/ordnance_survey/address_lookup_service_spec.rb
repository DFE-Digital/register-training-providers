require "rails_helper"

RSpec.describe OrdnanceSurvey::AddressLookupService do
  describe ".call" do
    let(:postcode) { "SW1A 2AA" }

    before do
      allow(Env).to receive(:ordnance_survey_api_key).and_return("test-key")
    end

    def stub_api_response(results)
      stub_request(:get, /api\.os\.uk/).to_return(
        status: 200,
        body: { "results" => results }.to_json
      )
    end

    def build_address(building_number:, **overrides)
      {
        "DPA" => {
          "BUILDING_NUMBER" => building_number,
          "THOROUGHFARE_NAME" => "DOWNING STREET",
          "POST_TOWN" => "LONDON",
          "POSTCODE" => "SW1A 2AA",
          "UPRN" => "100023336956",
          "LAT" => 51.5034,
          "LNG" => -0.1278
        }.merge(overrides)
      }
    end

    it "parses addresses, titleizes fields, and includes coordinates" do
      stub_api_response([
        build_address(
          building_number: "10",
          "ORGANISATION_NAME" => "PRIME MINISTER & FIRST LORD OF THE TREASURY"
        )
      ])

      result = described_class.call(postcode:)

      expect(result).to contain_exactly(
        hash_including(
          "organisation_name" => "Prime Minister & First Lord Of The Treasury",
          "address_line_1" => "10, Downing Street",
          "town_or_city" => "London",
          "postcode" => "SW1A 2AA",
          "uprn" => "100023336956",
          "latitude" => 51.5034,
          "longitude" => -0.1278
        )
      )
    end

    it "filters results by building name or number" do
      stub_api_response([
        build_address(building_number: "10"),
        build_address(building_number: "11")
      ])

      result = described_class.call(postcode: postcode, building_name_or_number: "10")

      expect(result.size).to eq(1)
      expect(result.first["address_line_1"]).to include("10")
    end

    it "returns empty array when no results found" do
      stub_api_response([])

      expect(described_class.call(postcode:)).to eq([])
    end

    it "returns empty array and logs error on API failure" do
      stub_request(:get, /api\.os\.uk/).to_raise(StandardError.new("Network error"))
      expect(Rails.logger).to receive(:error).with(/OS Places API error/)

      expect(described_class.call(postcode:)).to eq([])
    end

    it "returns empty array on non-success HTTP response" do
      stub_request(:get, /api\.os\.uk/).to_return(status: 500)

      expect(described_class.call(postcode:)).to eq([])
    end
  end
end
