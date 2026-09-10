require "rails_helper"

RSpec.describe Providers::ApplyProviderChangesJob, type: :job do
  subject(:perform) { described_class.new.perform }

  describe "#perform" do
    it "applies pending changes effective on or before today" do
      provider = create(:provider, code: "OLD")
      change = create(:provider_change, provider: provider, value: "ABC", effective_on: Date.current)

      perform

      expect(provider.reload.code).to eq("ABC")
      expect(change.reload).to be_completed
    end

    it "does not apply changes that are not yet effective" do
      provider = create(:provider, code: "OLD")
      change = create(:provider_change, provider: provider, value: "ABC", effective_on: Date.current + 1.day)

      perform

      expect(provider.reload.code).to eq("OLD")
      expect(change.reload).to be_pending
    end

    it "does not apply changes that are not pending" do
      provider = create(:provider, code: "OLD")
      change = create(:provider_change, provider: provider, value: "ABC", effective_on: Date.current, status: :completed)

      perform

      expect(provider.reload.code).to eq("OLD")
      expect(change.reload.processed_at).to be_nil
    end

    it "applies the earliest effective change when two changes conflict" do
      later_provider = create(:provider, code: "NEW")
      earlier_provider = create(:provider, code: "OLD")
      later = create(:provider_change, provider: later_provider, value: "AAA", effective_on: Date.current + 1.day)
      earlier = create(:provider_change, provider: earlier_provider, value: "AAA", effective_on: Date.current)

      Timecop.freeze(Date.current + 2.days) { perform }

      expect(earlier.reload).to be_completed
      expect(earlier_provider.reload.code).to eq("AAA")
      expect(later.reload).to be_failed
      expect(later.error_message).to be_present
      expect(later_provider.reload.code).to eq("NEW")
    end
  end
end
