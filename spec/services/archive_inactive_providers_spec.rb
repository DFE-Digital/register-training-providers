RSpec.describe ArchiveInactiveProviders do
  subject { described_class.call }

  let(:active_provider) { create(:provider) }
  let(:newly_inactive_provider) { create(:provider, inactive_periods: [{ start_date: 1.year.ago, end_date: nil }]) }
  let(:old_inactive_provider) { create(:provider, inactive_periods: [{ start_date: 3.years.ago, end_date: nil }]) }

  it "should archive providers who have been inactive for more than three years" do
    expect(old_inactive_provider.archived?).to eq(false)

    subject
    old_inactive_provider.reload

    expect(old_inactive_provider.archived?).to eq(true)
  end

  it "should set an end date on the archived providers inactive period" do
    old_inactive_provider
    subject
    old_inactive_provider.reload

    expect(old_inactive_provider.current_inactive_period).to eq(nil)
    # Exclusive end: the archive is effective today, so the period ends
    # yesterday, matching the status history rendering.
    expect(old_inactive_provider.inactive_periods.sole["end_date"]).to eq(Time.zone.yesterday.to_s)
  end

  it "should not archive providers who have been inactive for less than three years" do
    expect(newly_inactive_provider.archived?).to eq(false)

    subject
    newly_inactive_provider.reload

    expect(newly_inactive_provider.archived?).to eq(false)
  end

  it "should not archive providers who are active" do
    expect(active_provider.archived?).to eq(false)

    subject
    active_provider.reload

    expect(active_provider.archived?).to eq(false)
  end

  it "does not archive providers whose only open period is offboarded" do
    # `Provider.inactive` matches an open offboarded period too; the sweep must
    # not close a deliberately off-boarded period behind the office's back.
    old_offboarded_provider = create(
      :provider,
      inactive_periods: [{ start_date: 4.years.ago.to_date, end_date: nil, offboarded: true }]
    )

    subject

    old_offboarded_provider.reload

    expect(old_offboarded_provider.archived?).to eq(false)
    expect(old_offboarded_provider.open_offboarded_period["end_date"]).to be_nil
  end

  it "does not archive a provider the office has soft deleted" do
    # `Provider.inactive` has no kept scope, but soft deletion is a deliberate
    # office act: the sweep must not archive it nor write a system "Archived"
    # history row against it.
    old_inactive_provider
    old_inactive_provider.discard!

    subject

    old_inactive_provider.reload

    expect(old_inactive_provider.discarded?).to eq(true)
    expect(old_inactive_provider.archived?).to eq(false)
    expect(old_inactive_provider.provider_changes
      .where(source: %w[requested system]).for_attribute("status")).to be_empty
  end

  it "skips a provider whose open inactive period closes between the select snapshot and the row lock" do
    # Simulates a concurrent reactivator winning the provider row lock first:
    # under the sweep's lock the reloaded row has no open inactive period, so
    # the stale select snapshot must be discarded (not crash the run).
    old_inactive_provider
    allow_any_instance_of(Provider).to receive(:with_lock).and_wrap_original do |original, &block|
      old_inactive_provider.inactive_periods = [{ start_date: 4.years.ago.to_date, end_date: Time.zone.today }]
      old_inactive_provider.save!
      original.call(&block)
    end

    expect { subject }.not_to raise_error

    old_inactive_provider.reload

    expect(old_inactive_provider.archived?).to eq(false)
    expect(old_inactive_provider.provider_changes
      .where(source: %w[requested system]).for_attribute("status")).to be_empty
  end
  it "records the archive as a completed system status change with a baseline of the state it held" do
    old_inactive_provider
    subject

    old_inactive_provider.reload

    changes = old_inactive_provider.reload.provider_changes
    statuses = changes.where(source: %w[requested system]).for_attribute("status")

    expect(statuses.count).to eq(1)
    expect(statuses.sole).to have_attributes(
      value: { "status" => "archived" },
      status: "completed",
      source: "system",
      creator: nil
    )
    expect(changes.baseline.sole.value).to eq({ "status" => "inactive" })
  end

  it "cancels a pending status change queued against the provider instead of applying it later" do
    create(:provider_change,
           :status_change,
           provider: old_inactive_provider,
           value: { "status" => "active" })

    expect { subject }.to change {
      old_inactive_provider.provider_changes.pending.for_attribute("status").count
    }.from(1).to(0)
  end

  it "does not re-record the archive on a retried run over an already archived provider" do
    old_inactive_provider
    subject
    subject

    old_inactive_provider.reload

    expect(old_inactive_provider.reload.provider_changes
      .where(source: %w[requested system]).for_attribute("status").count).to eq(1)
  end

  it "leaves no recorded status change behind if archiving fails midway" do
    old_inactive_provider
    allow_any_instance_of(Provider).to receive(:archive!).and_raise(StandardError, "boom")

    expect { subject }.to raise_error(StandardError, "boom")

    old_inactive_provider.reload

    expect(old_inactive_provider.archived?).to eq(false)
    expect(old_inactive_provider.provider_changes
      .where(source: %w[requested system]).for_attribute("status").count).to eq(0)
  end
end
