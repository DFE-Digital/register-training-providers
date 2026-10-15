class ArchiveInactiveProviders
  include ServicePattern

  def self.age_to_archive_inactive_providers
    3.years.ago
  end

  def call
    # `Provider.inactive` has no kept/default scope, so a provider the office
    # discarded while inactive stays in the select snapshot; the predicate
    # below keeps it (and off-boarded providers) out of the sweep.
    providers = Provider.inactive.select { |provider| archivable?(provider) }

    providers.each do |provider|
      provider.with_lock do
        # with_lock re-loads the row, so archivable? runs again against the
        # committed state: a manual archiver, off-boarder, discarder or
        # reactivator racing this run serialises here and the stale select
        # snapshot is discarded — without the re-check the reloaded
        # current_inactive_period can blink out and the mutating block would
        # crash (or archive a provider the office has since dealt with).
        next unless archivable?(provider)

        # Record, period close and archive! must commit together: a completed
        # "Archived" row against an unarchived provider would be a half-recorded
        # state that a retried run duplicates.
        Providers::RecordStatusChange.call(provider: provider, status_value: "archived")

        # The archive takes effect today, so the inactive period ends the day
        # before — the exclusive convention used by
        # ApplyStatusChangeService#close_open_periods and the status history
        # (ProviderChangeHelper#change_period_end). Using today here would
        # render the same period with two different end dates.
        provider.current_inactive_period["end_date"] = Time.zone.yesterday

        provider.archive!
      end
    end
  end

private

  def archivable?(provider)
    # Soft deletion and off-boarding are deliberate office acts with their own
    # lifecycles — the nightly sweep must not close their open periods or write
    # a system "Archived" history row against them.
    return false if provider.discarded?
    return false if provider.archived?
    return false if provider.open_offboarded_period.present?

    period = provider.current_inactive_period

    return false if period.blank?

    period["start_date"].to_date <= self.class.age_to_archive_inactive_providers
  end
end
