require "rails_helper"

RSpec.describe Address, type: :model do
  let(:address) { create(:address) }

  it { is_expected.to be_audited }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
  end

  describe "factory" do
    it "creates a valid address" do
      expect(address).to be_valid
      expect(address).to be_persisted
    end
  end
end
