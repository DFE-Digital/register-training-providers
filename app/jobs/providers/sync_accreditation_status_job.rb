module Providers
  class SyncAccreditationStatusJob < ApplicationJob
    def perform
      providers_to_sync = providers_with_potential_status_changes

      synced_count = 0
      providers_to_sync.find_each do |provider|
        old_status = provider.accreditation_status
        provider.sync_accreditation_status!

        synced_count += 1 if provider.accreditation_status != old_status
      end

      Rails.logger.info(
        "Accreditation status sync completed: #{synced_count} providers updated",
      ) if synced_count.positive?
    end

  private

    def providers_with_potential_status_changes
      date_range = 1.day.ago..Date.current

      Provider.joins(:accreditations)
        .where(accreditations: { start_date: date_range })
        .or(Provider.joins(:accreditations).where(accreditations: { end_date: date_range }))
        .distinct
        .includes(:accreditations)
    end
  end
end
