require "rails_helper"

RSpec.describe Address, type: :model do
  let(:address) { create(:address) }

  it { is_expected.to be_audited }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:address_line_1) }
    it { is_expected.to validate_presence_of(:town_or_city) }
    it { is_expected.to validate_presence_of(:postcode) }

    describe "#types" do
      let(:address_with_valid_types) { build(:address, types: [:registered, :trading, :location]) }
      let(:address_with_invalid_types) { build(:address, types: [:registered, :wrong, :location]) }

      it "accepts valid address types" do
        address_with_valid_types.validate

        expect(address_with_valid_types.errors[:types]).to be_empty
      end

      it "does not accept invalid address types" do
        address_with_invalid_types.validate

        expect(address_with_invalid_types.errors[:types]).to include("Address types invalid")
      end
    end
  end

  describe "factory" do
    it "creates a valid address" do
      expect(address).to be_valid
      expect(address).to be_persisted
    end
  end
end
