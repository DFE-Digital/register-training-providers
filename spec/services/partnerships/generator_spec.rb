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

  describe ".call" do
    before do
      create(:provider, :scitt_without_accreditation)
      create(:provider, :hei)
    end

    it "creates a recruitment partnership type for every generated partnership" do
      described_class.call(percentage: 1.0)

      expect(Partnership.count).to be_positive
      expect(PartnershipType.where(partnership_type: PartnershipTypeEnum::RECRUITMENT).count)
        .to eq(Partnership.count)
    end

    it "skips a partner that already has a current partnership with the accredited provider" do
      already_partnered = create(:provider, :scitt_without_accreditation)
      unpartnered = create(:provider, :scitt_without_accreditation)
      accredited_provider = Provider.accredited.sole
      existing = create(:partnership, provider: already_partnered, accredited_provider: accredited_provider)

      expect { described_class.call(percentage: 1.0) }.not_to raise_error

      expect(Partnership.where(provider: already_partnered).pluck(:id)).to eq([existing.id])
      expect(Partnership.where(provider: unpartnered).count).to eq(1)
    end
  end
end
