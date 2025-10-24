require "rails_helper"

RSpec.describe Addresses::GeocodeService do
  describe ".call" do
    let(:postcode) { "SW1A 2AA" }
    let(:api_key) { "test-api-key" }

    before do
      allow(ENV).to receive(:fetch).with("ORDNANCE_SURVEY_API_KEY").and_return(api_key)
    end

    context "when the API returns coordinates" do
      let(:response_body) do
        {
          "results" => [
            {
              "DPA" => {
                "LATITUDE" => 51.503396,
                "LONGITUDE" => -0.127764
              }
            }
          ]
        }.to_json
      end

      it "returns latitude and longitude" do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 200, body: response_body)

        result = described_class.call(postcode:)

        expect(result[:latitude]).to eq(51.503396)
        expect(result[:longitude]).to eq(-0.127764)
      end
    end

    context "when no results are found" do
      it "returns nil coordinates" do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 200, body: { "results" => [] }.to_json)

        result = described_class.call(postcode:)

        expect(result[:latitude]).to be_nil
        expect(result[:longitude]).to be_nil
      end
    end

    context "when the API returns an error" do
      it "returns nil coordinates" do
        stub_request(:get, /api\.os\.uk/)
          .to_return(status: 500)

        result = described_class.call(postcode:)

        expect(result[:latitude]).to be_nil
        expect(result[:longitude]).to be_nil
      end
    end

    context "when the API request fails" do
      it "returns nil coordinates and logs the error" do
        stub_request(:get, /api\.os\.uk/)
          .to_raise(StandardError.new("Network error"))

        expect(Rails.logger).to receive(:error).with(/OS Places API geocoding error/)

        result = described_class.call(postcode:)

        expect(result[:latitude]).to be_nil
        expect(result[:longitude]).to be_nil
      end
    end
  end
end
