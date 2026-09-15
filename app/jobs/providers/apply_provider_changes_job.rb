module Providers
  class ApplyProviderChangesJob < ApplicationJob
    def perform
      ProviderChange
        .pending
        .where(effective_on: ..Date.current)
        .order(effective_on: :asc, created_at: :asc)
        .each do |change|
          ApplyProviderChangeJob.perform_now(change.id)
        end
    end
  end
end
