require "rails_helper"

RSpec.describe Providers::SyncAccreditationStatusJob, type: :job do
  describe "#perform" do
    it "syncs providers with recently started accreditations" do
      provider = create(:provider, :unaccredited)
      create(:accreditation, provider: provider, start_date: 1.day.ago, end_date: 1.year.from_now)
      provider.update_column(:accreditation_status, "unaccredited")

      expect { described_class.new.perform }
        .to change { provider.reload.accreditation_status }
        .from("unaccredited").to("accredited")
    end

    it "syncs providers with recently ended accreditations" do
      provider = create(:provider, :unaccredited)
      create(:accreditation, provider: provider, start_date: 1.year.ago, end_date: 1.day.ago)
      provider.update_column(:accreditation_status, "accredited")

      expect { described_class.new.perform }
        .to change { provider.reload.accreditation_status }
        .from("accredited").to("unaccredited")
    end

    it "processes multiple providers with status changes" do
      provider1 = create(:provider, :unaccredited)
      provider2 = create(:provider, :unaccredited)

      create(:accreditation, provider: provider1, start_date: 1.day.ago, end_date: 1.year.from_now)
      create(:accreditation, provider: provider2, start_date: 1.year.ago, end_date: 1.day.ago)

      provider1.update_column(:accreditation_status, "unaccredited")
      provider2.update_column(:accreditation_status, "accredited")

      described_class.new.perform

      expect(provider1.reload.accreditation_status).to eq("accredited")
      expect(provider2.reload.accreditation_status).to eq("unaccredited")
    end
  end
end
