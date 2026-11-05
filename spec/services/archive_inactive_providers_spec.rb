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
    expect(old_inactive_provider.inactive_periods.sole["end_date"]).to eq(Time.zone.yesterday.to_s)
  end

  it "closes every open inactive period, not just the first" do
    provider = create(
      :provider,
      inactive_periods: [
        { start_date: 4.years.ago.to_date, end_date: nil },
        { start_date: 3.years.ago.to_date - 1.day, end_date: nil }
      ]
    )

    subject
    provider.reload

    expect(provider.current_inactive_period).to be_nil
    expect(provider.inactive_periods.pluck("end_date"))
      .to eq([Time.zone.yesterday.to_s, Time.zone.yesterday.to_s])
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
      value: { "status" => "archived", "previous_status" => "inactive" },
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

  it "continues the sweep when archiving one provider raises" do
    failing = create(:provider, inactive_periods: [{ start_date: 3.years.ago, end_date: nil }])
    succeeding = create(:provider, inactive_periods: [{ start_date: 3.years.ago, end_date: nil }])

    allow(Providers::RecordStatusChange).to receive(:call).and_wrap_original do |original, **args|
      raise "boom" if args[:provider].id == failing.id

      original.call(**args)
    end
    allow(Rails.logger).to receive(:error)

    expect { subject }.not_to raise_error

    expect(Rails.logger).to have_received(:error).with(
      hash_including(event: "provider_archive_failed", provider_id: failing.id, error_message: "boom")
    )

    failing.reload
    expect(failing.archived?).to eq(false)
    expect(failing.provider_changes
      .where(source: %w[requested system]).for_attribute("status").count).to eq(0)
    expect(succeeding.reload).to be_archived
  end

  it "isolates a provider whose eligibility check raises" do
    malformed = create(:provider, inactive_periods: [{ start_date: 3.years.ago, end_date: nil }])
    succeeding = create(:provider, inactive_periods: [{ start_date: 3.years.ago, end_date: nil }])

    allow_any_instance_of(Provider).to receive(:current_inactive_period).and_wrap_original do |original, *args|
      raise "bad period" if original.receiver.id == malformed.id

      original.call(*args)
    end
    allow(Rails.logger).to receive(:error)

    expect { subject }.not_to raise_error

    expect(Rails.logger).to have_received(:error).with(
      hash_including(event: "provider_archive_failed", provider_id: malformed.id, error_message: "bad period")
    )
    expect(succeeding.reload).to be_archived
  end
end
