require "rails_helper"

RSpec.describe Providers::ArchiveInactiveProvidersJob, type: :job do
  describe "#perform" do
    it "archives providers who have been inactive for more than three years" do
      newly_inactive_provider = create(:provider, inactive_periods: [{ start_date: 1.year.ago, end_date: nil }])
      old_inactive_provider = create(:provider, inactive_periods: [{ start_date: 3.years.ago, end_date: nil }])

      described_class.new.perform

      expect(old_inactive_provider.reload.archived?).to eq(true)
      expect(newly_inactive_provider.reload.archived?).to eq(false)
    end
  end
end
