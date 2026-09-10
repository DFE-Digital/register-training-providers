module Providers
  class ApplyProviderChangeJob < ApplicationJob
    def perform(provider_change_id)
      change = ProviderChange.find(provider_change_id)

      return if change.effective_on > Date.current
      return if change.completed?

      saved = change.provider.update(
        change.attribute_name => change.value
      )

      change.update!(
        status: saved ? :completed : :failed,
        error_message: saved ? nil : change.provider.errors.full_messages.join(", "),
        processed_at: Time.current
      )
    end
  end
end
