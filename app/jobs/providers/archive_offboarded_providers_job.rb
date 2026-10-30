module Providers
  class ArchiveOffboardedProvidersJob < ApplicationJob
    def perform
      archived_count = Provider.archived.count

      ArchiveOffboardedProviders.call

      archived_count = Provider.archived.count - archived_count

      Rails.logger.info(
        "Archive offboarded providers job #{archived_count} providers archived",
      ) if archived_count.positive?
    end
  end
end
