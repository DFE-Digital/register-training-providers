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

    it "generates 1-2 addresses for providers without addresses" do
      expect { subject }.to(change { Address.count })

      provider_without_address.reload
      provider_with_address.reload

      expect(provider_without_address.addresses.count).to be_between(1, 2)
      expect(provider_with_address.addresses.count).to be >= 1 # Already had one, plus could get 1-2 more
    end

    it "returns the service instance with results" do
      result = subject

      expect(result).to be_a(Generators::Addresses)
      expect(result.total_addressable).to eq(2) # Both providers
      expect(result.providers_addressed).to eq(2) # All providers get addresses (since percentage is 1.0)
    end

    it "creates addresses with all required attributes" do
      subject

      # Check both providers have the expected number of addresses
      expect(provider_without_address.reload.addresses.count).to be_between(1, 2)
      expect(provider_with_address.reload.addresses.count).to be >= 1

      # Check all addresses have required attributes
      [provider_without_address, provider_with_address].each do |provider|
        provider.addresses.each do |address|
          expect(address.address_line_1).to be_present
          expect(address.town_or_city).to be_present
          expect(address.postcode).to be_present
          expect(address.provider_id).to eq(provider.id)
        end
      end
    end
  end
end
