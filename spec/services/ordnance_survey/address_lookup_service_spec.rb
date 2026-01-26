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

    def build_address(building_number:, sub_building: nil, building_name: nil, **overrides)
      {
        "DPA" => {
          "SUB_BUILDING_NAME" => sub_building,
          "BUILDING_NAME" => building_name,
          "BUILDING_NUMBER" => building_number,
          "DEPENDENT_THOROUGHFARE_NAME" => "DOWNING STREET",
          "THOROUGHFARE_NAME" => "DOWNING STREET",
          "DOUBLE_DEPENDENT_LOCALITY" => "WESTMINSTER",
          "DEPENDENT_LOCALITY" => "WESTMINSTER",
          "POST_TOWN" => "LONDON",
          "POSTCODE" => "SW1A 2AA",
          "UPRN" => "100023336956",
          "LAT" => 51.5034,
          "LNG" => -0.1278
        }.merge(overrides)
      }
    end

    it "parses addresses correctly with titleized lines and coordinates" do
      stub_api_response([
        build_address(building_number: "10", building_name: "The Prime Minister's Residence")
      ])

      result = described_class.call(postcode:)

      expect(result).to contain_exactly(
        hash_including(
          uprn: "100023336956",
          address_line_1: "The Prime Minister's Residence",
          address_line_2: "10, Downing Street, Downing Street",
          address_line_3: "Westminster, Westminster",
          town_or_city: "London",
          postcode: "SW1A 2AA",
          latitude: 51.5034,
          longitude: -0.1278
        )
      )
    end

    it "handles sub-building names correctly" do
      stub_api_response([
        build_address(building_number: "10", sub_building: "Flat 1")
      ])

      result = described_class.call(postcode:)

      expect(result.first[:address_line_1]).to eq("Flat 1")
      expect(result.first[:address_line_2]).to eq("10, Downing Street, Downing Street")
    end

    it "filters by building name or number in address_line_1" do
      stub_api_response([
        build_address(building_number: "10", building_name: "The Prime Minister's Residence"),
        build_address(building_number: "11")
      ])

      result = described_class.call(postcode: postcode, building_name_or_number: "11")

      expect(result.size).to eq(1)
      expect(result.first[:address_line_1]).to include("11, Downing Street, Downing Street")
    end

    it "returns empty array when no results are found" do
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
