require "rails_helper"

RSpec.describe Generators::Partnerships, type: :service do
  describe "#target_providers" do
    let!(:unaccredited_scitt) { create(:provider, :scitt_without_accreditation) }
    let!(:unaccredited_school) { create(:provider, :school) }
    let!(:accredited_school) { create(:provider, :school_with_accreditation) }
    let!(:accredited_hei) { create(:provider, :hei) }
    let!(:previously_accredited_scitt) do
      provider = create(:provider, :scitt)
      provider.accreditations.update_all(end_date: 1.day.ago)
      provider.sync_accreditation_status!
      provider
    end

    subject(:target_ids) { described_class.send(:new).send(:target_providers).pluck(:id) }

    it "includes unaccredited providers regardless of provider type" do
      expect(target_ids).to include(unaccredited_scitt.id, unaccredited_school.id)
    end

    it "excludes accredited providers" do
      expect(target_ids).not_to include(accredited_school.id, accredited_hei.id)
    end

    it "excludes unaccredited providers that have historical accreditations" do
      expect(previously_accredited_scitt.reload.accreditation_status).to eq("unaccredited")

      expect(target_ids).not_to include(previously_accredited_scitt.id)
    end
  end
end
