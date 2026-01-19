require "rails_helper"

RSpec.describe OrdnanceSurvey::AddressParserService do
  describe "#call" do
    let(:dpa) do
      {
        "ORGANISATION_NAME" => "Birch School",
        "SUB_BUILDING_NAME" => "Flat 2",
        "BUILDING_NAME" => "The Oaks",
        "BUILDING_NUMBER" => "123",
        "DEPENDENT_THOROUGHFARE_NAME" => "High Street",
        "THOROUGHFARE_NAME" => "Main Road",
        "DOUBLE_DEPENDENT_LOCALITY" => "Hamlet",
        "DEPENDENT_LOCALITY" => "Village",
        "POST_TOWN" => "London",
        "POSTCODE" => "SW1A 1AA",
        "UPRN" => "1000001",
        "LAT" => 51.5,
        "LNG" => -0.12
      }
    end

    subject { described_class.call(dpa) }

    it "parses all fields into address lines correctly" do
      expect(subject[:organisation_name]).to eq("Birch School")
      expect(subject[:address_line_1]).to eq("Flat 2, The Oaks")
      expect(subject[:address_line_2]).to eq("123, High Street, Main Road")
      expect(subject[:address_line_3]).to eq("Hamlet, Village")
      expect(subject[:town_or_city]).to eq("London")
      expect(subject[:postcode]).to eq("SW1A 1AA")
      expect(subject[:uprn]).to eq("1000001")
      expect(subject[:latitude]).to eq(51.5)
      expect(subject[:longitude]).to eq(-0.12)
    end

    it "puts building number and street into line 1 if no sub-building or building name" do
      dpa["SUB_BUILDING_NAME"] = nil
      dpa["BUILDING_NAME"] = nil

      expect(subject[:address_line_1]).to eq("123, High Street, Main Road")
      expect(subject[:address_line_2]).to eq("Hamlet, Village")
      expect(subject[:address_line_3]).to eq("")
    end

    it "handles missing localities" do
      dpa["DOUBLE_DEPENDENT_LOCALITY"] = nil
      dpa["DEPENDENT_LOCALITY"] = nil

      expect(subject[:address_line_3]).to eq("")
    end

    it "handles only building name and no sub-building" do
      dpa["SUB_BUILDING_NAME"] = nil

      expect(subject[:address_line_1]).to eq("The Oaks")
      expect(subject[:address_line_2]).to eq("123, High Street, Main Road")
      expect(subject[:address_line_3]).to eq("Hamlet, Village")
    end

    it "handles only sub-building and no building name" do
      dpa["BUILDING_NAME"] = nil

      expect(subject[:address_line_1]).to eq("Flat 2")
      expect(subject[:address_line_2]).to eq("123, High Street, Main Road")
      expect(subject[:address_line_3]).to eq("Hamlet, Village")
    end

    it "titleizes all relevant fields" do
      dpa.merge!(
        "SUB_BUILDING_NAME" => "flat 3a",
        "BUILDING_NAME" => "oak villa",
        "BUILDING_NUMBER" => "10b",
        "DEPENDENT_THOROUGHFARE_NAME" => "lower street",
        "THOROUGHFARE_NAME" => "main road",
        "DOUBLE_DEPENDENT_LOCALITY" => "hamlet",
        "DEPENDENT_LOCALITY" => "village",
        "POST_TOWN" => "london"
      )

      expect(subject[:address_line_1]).to eq("Flat 3a, Oak Villa")
      expect(subject[:address_line_2]).to eq("10b, Lower Street, Main Road")
      expect(subject[:address_line_3]).to eq("Hamlet, Village")
      expect(subject[:town_or_city]).to eq("London")
    end

    it "handles missing everything except postcode and town" do
      dpa.merge!(
        "SUB_BUILDING_NAME" => nil,
        "BUILDING_NAME" => nil,
        "BUILDING_NUMBER" => nil,
        "DEPENDENT_THOROUGHFARE_NAME" => nil,
        "THOROUGHFARE_NAME" => nil,
        "DOUBLE_DEPENDENT_LOCALITY" => nil,
        "DEPENDENT_LOCALITY" => nil
      )

      expect(subject[:address_line_1]).to eq("")
      expect(subject[:address_line_2]).to eq("")
      expect(subject[:address_line_3]).to eq("")
      expect(subject[:town_or_city]).to eq("London")
      expect(subject[:postcode]).to eq("SW1A 1AA")
    end
  end
end
