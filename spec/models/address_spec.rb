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
  end

  describe "factory" do
    it "creates a valid address" do
      expect(address).to be_valid
      expect(address).to be_persisted
    end
  end

  describe "geocoding" do
    let(:provider) { create(:provider) }

    context "when saving a new address without coordinates" do
      it "geocodes the address" do
        allow(Addresses::GeocodeService).to receive(:call).and_return(
          { latitude: 51.503396, longitude: -0.127764 }
        )

        address = Address.new(
          provider: provider,
          address_line_1: "10 Downing Street",
          town_or_city: "London",
          postcode: "SW1A 2AA"
        )

        address.save!

        expect(Addresses::GeocodeService).to have_received(:call).with(postcode: "SW1A 2AA")
        expect(address.latitude).to eq(51.503396)
        expect(address.longitude).to eq(-0.127764)
      end
    end

    context "when saving an address with existing coordinates" do
      it "does not geocode again" do
        allow(Addresses::GeocodeService).to receive(:call)

        address = Address.new(
          provider: provider,
          address_line_1: "10 Downing Street",
          town_or_city: "London",
          postcode: "SW1A 2AA",
          latitude: 51.5,
          longitude: -0.1
        )

        address.save!

        expect(Addresses::GeocodeService).not_to have_received(:call)
        expect(address.latitude).to eq(51.5)
        expect(address.longitude).to eq(-0.1)
      end
    end

    context "when geocoding fails" do
      it "saves the address with nil coordinates" do
        allow(Addresses::GeocodeService).to receive(:call).and_return(
          { latitude: nil, longitude: nil }
        )

        address = Address.new(
          provider: provider,
          address_line_1: "Unknown Address",
          town_or_city: "Unknown",
          postcode: "XX1 1XX"
        )

        address.save!

        expect(address.latitude).to be_nil
        expect(address.longitude).to be_nil
      end
    end

    context "when postcode is blank" do
      it "does not attempt to geocode" do
        allow(Addresses::GeocodeService).to receive(:call)

        address = Address.new(
          provider: provider,
          address_line_1: "Test",
          town_or_city: "Test",
          postcode: nil
        )

        address.save!(validate: false)

        expect(Addresses::GeocodeService).not_to have_received(:call)
      end
    end
  end
end
