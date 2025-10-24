require "rails_helper"

RSpec.describe OrdnanceSurvey::AddressLookupService do
  describe ".call" do
    let(:postcode) { "SW1A 2AA" }
    let(:api_key) { "test-api-key" }

    before do
      allow(ENV).to receive(:fetch).with("ORDNANCE_SURVEY_API_KEY").and_return(api_key)
    end

    context "when searching by postcode only" do
      let(:response_body) do
        {
          "results" => [
            {
              "DPA" => {
                "ORGANISATION_NAME" => "Prime Minister & First Lord Of The Treasury",
                "BUILDING_NUMBER" => "10",
                "THOROUGHFARE_NAME" => "Downing Street",
                "POST_TOWN" => "London",
                "POSTCODE" => "SW1A 2AA",
                "LATITUDE" => 51.503396,
                "LONGITUDE" => -0.127764
              }
            }
          ]
        }.to_json
      end

      it "returns parsed addresses" do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 200, body: response_body)

        result = described_class.call(postcode: postcode)

        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
        expect(result.first[:address_line_1]).to eq("Prime Minister & First Lord Of The Treasury, 10, Downing Street")
        expect(result.first[:town_or_city]).to eq("London")
        expect(result.first[:postcode]).to eq("SW1A 2AA")
        expect(result.first[:latitude]).to eq(51.503396)
        expect(result.first[:longitude]).to eq(-0.127764)
      end
    end

    context "when searching with building name or number" do
      let(:building) { "10" }

      it "uses the find endpoint" do
        stub = stub_request(:get, %r{api\.os\.uk/search/places/v1/find})
          .with(query: hash_including("query" => "#{building} #{postcode}"))
          .to_return(status: 200, body: { "results" => [] }.to_json)

        described_class.call(postcode: postcode, building_name_or_number: building)

        expect(stub).to have_been_requested
      end
    end

    context "when no results are found" do
      it "returns an empty array" do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 200, body: { "results" => [] }.to_json)

        result = described_class.call(postcode: postcode)

        expect(result).to eq([])
      end
    end

    context "when the API returns an error" do
      it "returns an empty array" do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 500)

        result = described_class.call(postcode: postcode)

        expect(result).to eq([])
      end
    end

    context "when the API request fails" do
      it "returns an empty array and logs the error" do
        stub_request(:get, /api\.os\.uk/)
          .to_raise(StandardError.new("Network error"))

        expect(Rails.logger).to receive(:error).with(/OS Places API error/)

        result = described_class.call(postcode: postcode)

        expect(result).to eq([])
      end
    end
  end
end

