require "rails_helper"

RSpec.describe Addresses::SearchResultsForm do
  describe "#results_array" do
    context "when results is a JSON string" do
      it "returns parsed array" do
        addresses = [
          { "address_line_1" => "10 Downing Street", "postcode" => "SW1A 2AA" }
        ]
        form = described_class.new(results: addresses.to_json)

        expect(form.results_array).to eq(addresses)
      end
    end

    context "when results is blank" do
      it "returns empty array" do
        form = described_class.new(results: nil)

        expect(form.results_array).to eq([])
      end
    end

    context "when results is invalid JSON" do
      it "returns empty array" do
        form = described_class.new(results: "invalid json")

        expect(form.results_array).to eq([])
      end
    end
  end

  describe "#results_array=" do
    it "stores array as JSON string" do
      form = described_class.new
      addresses = [
        { "address_line_1" => "10 Downing Street", "postcode" => "SW1A 2AA" }
      ]

      form.results_array = addresses

      expect(form.results).to eq(addresses.to_json)
      expect(form.results_array).to eq(addresses)
    end
  end

  describe "attributes" do
    it "has selected_address_index attribute" do
      form = described_class.new(selected_address_index: 2)
      expect(form.selected_address_index).to eq(2)
    end
  end

  describe "#serializable_hash" do
    it "returns attributes hash" do
      form = described_class.new(
        results: '[{"address": "test"}]',
        selected_address_index: 1
      )

      hash = form.serializable_hash

      expect(hash["results"]).to eq('[{"address": "test"}]')
      expect(hash["selected_address_index"]).to eq(1)
    end
  end
end
