module Providers
  class ArchiveInactiveProvidersJob < ApplicationJob
    def perform
      archived_count = Provider.archived.count

      ArchiveInactiveProviders.call

      archived_count -= Provider.archived.count

      archived_count *= -1

      Rails.logger.info(
        "Archive inactive providers job #{archived_count} providers archived",
      ) if archived_count.positive?
    end
  end
end
