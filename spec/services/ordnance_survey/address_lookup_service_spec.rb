require "rails_helper"

RSpec.describe OrdnanceSurvey::AddressLookupService do
  describe ".call" do
    let(:postcode) { "SW1A 2AA" }
    let(:api_key) { "test-api-key" }

    before do
      allow(Env).to receive(:ordnance_survey_api_key).and_return(api_key)
    end

    context "when searching by postcode only" do
      let(:response_body) do
        {
          "results" => [
            {
              "DPA" => {
                "ORGANISATION_NAME" => "PRIME MINISTER & FIRST LORD OF THE TREASURY",
                "BUILDING_NUMBER" => "10",
                "THOROUGHFARE_NAME" => "DOWNING STREET",
                "POST_TOWN" => "LONDON",
                "POSTCODE" => "SW1A 2AA",
                "LAT" => 51.503396,
                "LNG" => -0.127764
              }
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 200, body: response_body)
      end

      it "returns parsed addresses with titleized fields and coordinates" do
        result = described_class.call(postcode:)

        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
        expect(result.first["address_line_1"]).to eq("Prime Minister & First Lord Of The Treasury, 10, Downing Street")
        expect(result.first["town_or_city"]).to eq("London")
        expect(result.first["postcode"]).to eq("SW1A 2AA")
        expect(result.first["latitude"]).to eq(51.503396)
        expect(result.first["longitude"]).to eq(-0.127764)
      end
    end

    context "when searching with building name or number" do
      let(:building) { "10" }
      let(:response_body) do
        {
          "results" => [
            {
              "DPA" => {
                "BUILDING_NUMBER" => "10",
                "THOROUGHFARE_NAME" => "DOWNING STREET",
                "POST_TOWN" => "LONDON",
                "POSTCODE" => "SW1A 2AA",
                "LAT" => 51.503396,
                "LNG" => -0.127764
              }
            },
            {
              "DPA" => {
                "BUILDING_NUMBER" => "11",
                "THOROUGHFARE_NAME" => "DOWNING STREET",
                "POST_TOWN" => "LONDON",
                "POSTCODE" => "SW1A 2AA",
                "LAT" => 51.503400,
                "LNG" => -0.127770
              }
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 200, body: response_body)
      end

      it "filters results by building name or number" do
        result = described_class.call(postcode: postcode, building_name_or_number: building)

        expect(result.size).to eq(1)
        expect(result.first["address_line_1"]).to eq("10, Downing Street")
        expect(result.first["latitude"]).to eq(51.503396)
        expect(result.first["longitude"]).to eq(-0.127764)
      end
    end

    context "when no results are found" do
      let(:response_body) { { "results" => [] }.to_json }

      before do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 200, body: response_body)
      end

      it "returns an empty array" do
        result = described_class.call(postcode:)

        expect(result).to eq([])
      end
    end

    context "when the API returns an error" do
      before do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 500)
      end

      it "returns an empty array" do
        result = described_class.call(postcode:)

        expect(result).to eq([])
      end
    end

    context "when the API request fails" do
      before do
        stub_request(:get, /api\.os\.uk/)
          .to_raise(StandardError.new("Network error"))
      end

      it "returns an empty array and logs the error" do
        expect(Rails.logger).to receive(:error).with(/OS Places API error/)

        result = described_class.call(postcode:)

        expect(result).to eq([])
      end
    end
  end
end
