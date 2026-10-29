require "rails_helper"

RSpec.describe Addresses::MarkAsHistoricService do
  let(:provider) { create(:provider) }
  let(:existing_address) { create(:address, types: [:location], provider: provider, created_at: 1.day.ago) }
  let(:new_address) { create(:address, types: [:location], provider: provider) }

  describe ".call" do
    it "adds an effective end date for location on the existing address" do
      expect {
        described_class.call(provider_id: provider.id, type: "location", new_address_id: new_address.id)
      }.to change {
        existing_address.reload.effective_end_dates
      }.from({}).to({ "location" => Time.zone.today.to_s })
    end
  end
end
