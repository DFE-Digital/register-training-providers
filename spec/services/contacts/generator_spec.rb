require "rails_helper"

RSpec.describe Generators::Contacts, type: :service do
  describe "#call" do
    let!(:provider_without_contact) { create(:provider) }
    let!(:provider_with_contact) { create(:provider) }
    let!(:contact) { create(:contact, provider: provider_with_contact) }

    subject { described_class.call(percentage: 1.0) }

    before do
      # Ensure we have providers without contacts to test with
      provider_without_contact
    end

    it "generates 1-2 contacts for providers without contacts" do
      expect { subject }.to(change { Contact.count })

      provider_without_contact.reload
      provider_with_contact.reload

      expect(provider_without_contact.contacts.count).to be_between(1, 2)
      expect(provider_with_contact.contacts.count).to be >= 1 # Already had one, plus could get 1-2 more
    end

    it "returns the service instance with results" do
      result = subject

      expect(result).to be_a(Generators::Contacts)
      expect(result.total_contactable).to eq(2) # Both providers
      expect(result.providers_contacted).to eq(2) # All providers get contacts (since percentage is 1.0)
    end

    it "creates contacts with all required attributes" do
      subject

      # Check both providers have the expected number of contactes
      expect(provider_without_contact.reload.contacts.count).to be_between(1, 2)
      expect(provider_with_contact.reload.contacts.count).to be >= 1

      # Check all contactes have required attributes
      [provider_without_contact, provider_with_contact].each do |provider|
        provider.contacts.each do |contact|
          expect(contact.first_name).to be_present
          expect(contact.last_name).to be_present
          expect(contact.email_address).to be_present
          expect(contact.telephone_number).to be_present
          expect(contact.provider_id).to eq(provider.id)
        end
      end
    end
  end
end
