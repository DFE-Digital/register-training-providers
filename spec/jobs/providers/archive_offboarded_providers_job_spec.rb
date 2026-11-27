require "rails_helper"

RSpec.describe Providers::ArchiveOffboardedProvidersJob, type: :job do
  describe "#perform" do
    it "archives providers who were still offboarded at the end of the academic year" do
      Timecop.freeze(Time.zone.local(2026, 8, 1, 4)) do
        previous_cycle = create(
          :provider,
          inactive_periods: [{ start_date: Date.new(2025, 9, 1), end_date: nil, offboarded: true }]
        )
        current_cycle = create(
          :provider,
          inactive_periods: [{ start_date: Date.new(2026, 8, 1), end_date: nil, offboarded: true }]
        )

        described_class.new.perform

        expect(previous_cycle.reload).to be_archived
        expect(current_cycle.reload).not_to be_archived
      end
    end
  end
end
