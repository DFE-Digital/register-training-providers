require "rails_helper"

RSpec.describe ArchiveOffboardedProviders do
  subject(:archive) { described_class.call }

  around do |example|
    Timecop.freeze(Time.zone.local(2026, 8, 1, 4)) { example.run }
  end

  def offboarded_provider(start_date)
    create(:provider, inactive_periods: [{ start_date: start_date, end_date: nil, offboarded: true }])
  end

  it "archives a provider that was still offboarded at the end of the academic year" do
    provider = offboarded_provider(Date.new(2025, 9, 1))

    archive

    provider.reload

    expect(provider).to be_archived
    expect(provider.open_offboarded_period).to be_nil
    expect(provider.inactive_periods.sole["end_date"]).to eq("2026-07-31")
  end

  it "records a system archive change effective 1 August" do
    provider = offboarded_provider(Date.new(2025, 9, 1))

    archive

    change = provider.reload.provider_changes.system.for_attribute("status").sole
    expect(change).to have_attributes(
      value: { "status" => "archived", "previous_status" => "offboarded" },
      effective_on: Date.new(2026, 8, 1),
      status: "completed"
    )
  end

  it "does not archive a provider offboarded on the first day of the current academic year" do
    provider = offboarded_provider(Date.new(2026, 8, 1))

    archive

    expect(provider.reload).not_to be_archived
  end

  it "does not archive a provider offboarded after the current academic year began" do
    provider = offboarded_provider(Date.new(2026, 9, 1))

    archive

    expect(provider.reload).not_to be_archived
  end

  it "does not archive a provider whose open period is inactive, not offboarded" do
    provider = create(:provider, inactive_periods: [{ start_date: Date.new(2025, 9, 1), end_date: nil }])

    archive

    expect(provider.reload).not_to be_archived
  end

  it "does not archive a discarded offboarded provider" do
    provider = offboarded_provider(Date.new(2025, 9, 1))
    provider.discard!

    archive

    expect(provider.reload).not_to be_archived
  end

  it "does not archive an already archived provider" do
    provider = offboarded_provider(Date.new(2025, 9, 1))
    provider.archive!

    expect { archive }.not_to(change { provider.reload.provider_changes.system.for_attribute("status").count })
  end

  it "is idempotent" do
    provider = offboarded_provider(Date.new(2025, 9, 1))
    archive

    expect { archive }.not_to(change { provider.reload.provider_changes.system.for_attribute("status").count })
  end

  it "skips a provider whose open offboarded period closes between the select snapshot and the row lock" do
    provider = offboarded_provider(Date.new(2025, 9, 1))

    allow_any_instance_of(Provider).to receive(:with_lock).and_wrap_original do |original, &block|
      provider.inactive_periods = [{
        start_date: Date.new(2025, 9, 1),
        end_date: Date.new(2026, 7, 31),
        offboarded: true
      }]
      provider.save!
      original.call(&block)
    end

    expect { archive }.not_to raise_error

    provider.reload

    expect(provider).not_to be_archived
    expect(provider.provider_changes.where(source: %w[requested system]).for_attribute("status")).to be_empty
  end

  it "continues the sweep when archiving one provider raises" do
    failing = offboarded_provider(Date.new(2025, 9, 1))
    succeeding = offboarded_provider(Date.new(2025, 9, 1))

    allow(Providers::RecordStatusChange).to receive(:call).and_wrap_original do |original, **args|
      raise "boom" if args[:provider].id == failing.id

      original.call(**args)
    end
    allow(Rails.logger).to receive(:error)

    expect { archive }.not_to raise_error

    expect(Rails.logger).to have_received(:error).with(
      hash_including(event: "provider_archive_failed", provider_id: failing.id, error_message: "boom")
    )

    expect(failing.reload).not_to be_archived
    expect(succeeding.reload).to be_archived
  end

  it "fails a pending change rather than destroying it when archiving" do
    provider = offboarded_provider(Date.new(2025, 9, 1))
    change = create(:provider_change, :status_change, provider: provider,
                                                      value: { "status" => "active" },
                                                      effective_on: Date.new(2026, 9, 1))

    archive

    expect(change.reload).to be_failed
    expect(change.error_message).to eq("Provider was archived before the change took effect")
  end

  it "catches up when it runs after 1 August" do
    provider = offboarded_provider(Date.new(2025, 9, 1))

    Timecop.freeze(Time.zone.local(2026, 8, 3, 4)) do
      archive
    end

    provider.reload

    expect(provider).to be_archived
    expect(provider.archived_at.to_date).to eq(Date.new(2026, 8, 1))
    expect(provider.provider_changes.system.for_attribute("status").sole.effective_on)
      .to eq(Date.new(2026, 8, 1))
    expect(Provider.for_active_academic_years([2026])).not_to include(provider)
  end
end
