require "rails_helper"

RSpec.describe Addresses::FindForm do
  describe "validations" do
    it { is_expected.to validate_presence_of(:postcode) }

    context "with a valid postcode" do
      subject { described_class.new(postcode: "SW1A 2AA") }

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "with an invalid postcode" do
      subject { described_class.new(postcode: "INVALID") }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:postcode]).to be_present
      end
    end

    context "with a blank postcode" do
      subject { described_class.new(postcode: "") }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:postcode]).to include("can't be blank")
      end
    end
  end

  describe "attributes" do
    it "has postcode attribute" do
      form = described_class.new(postcode: "SW1A 2AA")
      expect(form.postcode).to eq("SW1A 2AA")
    end

    it "has building_name_or_number attribute" do
      form = described_class.new(building_name_or_number: "10")
      expect(form.building_name_or_number).to eq("10")
    end

    it "has provider_id attribute" do
      form = described_class.new(provider_id: "123")
      expect(form.provider_id).to eq("123")
    end
  end

  describe "#serializable_hash" do
    it "returns attributes hash" do
      form = described_class.new(
        postcode: "SW1A 2AA",
        building_name_or_number: "10",
        provider_id: "123"
      )

      hash = form.serializable_hash

      expect(hash["postcode"]).to eq("SW1A 2AA")
      expect(hash["building_name_or_number"]).to eq("10")
      expect(hash["provider_id"]).to eq("123")
    end
  end
end
