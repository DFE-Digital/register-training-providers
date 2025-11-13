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
end
