require "rails_helper"

RSpec.describe Addresses::FindForm, type: :model do
  subject { described_class.new(postcode: "SW1A 2AA") }

  describe "validations" do
    it "is valid with a valid postcode" do
      expect(subject).to be_valid
    end

    it "requires postcode" do
      subject.postcode = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:postcode]).to include("Enter postcode")
    end

    it "validates postcode format" do
      subject.postcode = "INVALID"
      expect(subject).not_to be_valid
      expect(subject.errors[:postcode]).to be_present
    end

    it "normalizes postcode" do
      subject.postcode = "  sw1a 2aa  "
      subject.valid?
      expect(subject.postcode).to eq("SW1A 2AA")
    end
  end
end
