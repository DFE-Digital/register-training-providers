require "rails_helper"
require Rails.root.join("db/migrate/20261021093000_backfill_open_inactive_periods_for_archived_providers")

RSpec.describe BackfillOpenInactivePeriodsForArchivedProviders do
  subject(:migrate) { described_class.new.up }

  def provider_with_open_period(traits:, archived_at: nil, start_date: Date.new(2025, 9, 1))
    create(
      :provider,
      *traits,
      archived_at: archived_at,
      inactive_periods: [{ start_date: start_date, end_date: nil }]
    )
  end

  it "closes an archived provider's open period the day before the archive date" do
    provider = provider_with_open_period(traits: [:archived], archived_at: Time.zone.local(2026, 8, 1, 4))

    migrate

    expect(provider.reload.inactive_periods.sole["end_date"]).to eq("2026-07-31")
  end

  it "leaves the open period of a provider that is not archived untouched" do
    provider = provider_with_open_period(traits: [])

    migrate

    expect(provider.reload.inactive_periods.sole["end_date"]).to be_nil
  end

  it "does not end a period before it began" do
    provider = provider_with_open_period(
      traits: [:archived],
      archived_at: Time.zone.local(2026, 8, 1, 4),
      start_date: Date.new(2026, 8, 1)
    )

    migrate

    expect(provider.reload.inactive_periods.sole["end_date"]).to eq("2026-08-01")
  end
end
