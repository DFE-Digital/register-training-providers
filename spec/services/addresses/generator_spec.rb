require "rails_helper"

RSpec.describe Generators::Addresses, type: :service do
  describe "#call" do
    let!(:provider_without_address) { create(:provider) }
    let!(:provider_with_address) { create(:provider) }
    let!(:address) { create(:address, provider: provider_with_address) }

    subject { described_class.call(percentage: 1.0) }

    before do
      # Ensure we have providers without addresses to test with
      provider_without_address
    end

    it "generates addresses for providers without addresses" do
      expect { subject }.to(change { Address.count })

      expect(provider_without_address.reload.addresses).to be_present
      expect(provider_with_address.reload.addresses).to be_present # Already had one, but could get more
    end

    it "returns the service instance with results" do
      result = subject

      expect(result).to be_a(Generators::Addresses)
      expect(result.total_addressable).to eq(2) # Both providers
      expect(result.providers_addressed).to be >= 1 # At least one provider got an address
    end

    it "creates addresses with all required attributes" do
      subject

      provider_without_address.reload.addresses.each do |address|
        expect(address.address_line_1).to be_present
        expect(address.town_or_city).to be_present
        expect(address.postcode).to be_present
        expect(address.provider_id).to eq(provider_without_address.id)
      end
    end
  end
end
