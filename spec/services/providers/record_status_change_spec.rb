require "rails_helper"

RSpec.describe Providers::RecordStatusChange, type: :service do
  subject(:record) do
    described_class.call(provider:, status_value:, creator:)
  end

  let(:provider) { create(:provider) }
  let(:creator) { create(:user) }
  let(:status_value) { "archived" }

  it "records the status change" do
    record

    change = provider.provider_changes.requested.for_attribute("status").sole
    expect(change).to have_attributes(
      attribute_name: "status",
      value: { "status" => "archived" },
      status: "completed",
      source: "requested",
      creator: creator
    )
    expect(change.effective_on).to eq(Date.current)
  end

  it "records a baseline of the status the provider had before the first change" do
    record

    baseline = provider.provider_changes.baseline.sole
    expect(baseline).to have_attributes(
      attribute_name: "status",
      value: { "status" => "active" },
      status: "completed"
    )
  end

  context "when a previous status is supplied" do
    # Restore mutates the provider before recording, so the caller passes the
    # status it held beforehand for the baseline to capture.
    it "records the supplied status in the baseline" do
      described_class.call(provider: provider, status_value: "active", previous_status: "archived", creator: creator)

      baseline = provider.provider_changes.baseline.for_attribute("status").sole
      expect(baseline.value).to eq("status" => "archived")
    end
  end

  context "when no creator is supplied (system-applied)" do
    let(:creator) { nil }

    it "records the status change as a system change" do
      record

      change = provider.provider_changes.system.for_attribute("status").sole
      expect(change).to have_attributes(
        attribute_name: "status",
        value: { "status" => "archived" },
        status: "completed",
        source: "system",
        creator: nil
      )
    end
  end

  context "when a baseline already exists" do
    before do
      create(:provider_change, :baseline, provider: provider, attribute_name: "status",
                                          value: { "status" => "inactive" })
    end

    it "does not add another baseline" do
      expect { record }.not_to(change { provider.provider_changes.baseline.count })
    end

    it "still records the status change" do
      record

      expect(provider.provider_changes.requested.for_attribute("status").count).to eq(1)
    end
  end
end
