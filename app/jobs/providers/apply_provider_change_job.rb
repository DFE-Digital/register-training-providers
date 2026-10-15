module Providers
  class ApplyProviderChangeJob < ApplicationJob
    def perform(provider_change_id)
      change = ProviderChange.find_by(id: provider_change_id)

      return if change.blank?
      return if change.effective_on > Date.current
      return if change.completed?

      if change.attribute_name == "status"
        mark_processed(change) do
          Providers::ApplyStatusChangeService.call(
            provider: change.provider,
            new_status: change.value["status"],
            effective_on: change.effective_on,
            reasons: ProviderStatusEnum.reason_labels_for(
              change.value["reason_ids"],
              change.value["other_reason"]
            )
          )
        end
      else
        mark_processed(change) do
          apply_with_row_lock(change)
        end
      end
    end

  private

    def apply_with_row_lock(change)
      # The status branch serialises through ApplyStatusChangeService's
      # provider row lock (which also re-checks discarded? against the locked
      # row). The generic attribute branch must do the same: with_lock
      # re-loads the locked row, so the archived?/discarded? guards below are
      # re-checked against the committed state — closing the check-then-act
      # gap left by the guards at the top of perform.
      change.provider.with_lock do
        next :archived if change.provider.archived?
        next :discarded if change.provider.discarded?

        # rubocop:disable Rails/SaveBang -- soft-fail so mark_processed can
        # record :failed with the provider's errors instead of raising
        change.provider.update(change.attribute_name => change.value)
        # rubocop:enable Rails/SaveBang
      end
    end

    def mark_processed(change)
      saved = yield

      # The provider's validation errors must be read from the provider
      # instance the apply ran on — re-resolving the change below loads a
      # fresh provider association whose errors are empty.
      error_message =
        case saved
        when :archived then "Provider was archived before the change could be applied"
        when :discarded then "Provider was discarded before the change could be applied"
        when false then change.provider.errors.full_messages.join(", ")
        end

      # A manual archive races us behind the row lock: it destroys the
      # pending change along with setting archived_at, so the change that
      # was read at the top of perform may be gone by now — and writing a
      # status to the destroyed row would raise. Re-resolve it; a gone row
      # has been resolved by the archive itself, nothing left to mark.
      change = ProviderChange.find_by(id: change.id)
      return if change.blank?

      change.update!(
        status: saved == true ? :completed : :failed,
        error_message: error_message,
        processed_at: Time.current
      )
    rescue StandardError => e
      # A raise inside the apply (e.g. a lock timeout or a mid-apply archive
      # that destroyed the pending change) must fail this change individually
      # instead of escaping and aborting the nightly queue, which would leave
      # every pending change behind it unprocessed and this change poisoned
      # (it would abort again on the next run). Re-finding the row tolerates a
      # destroyed change: nil means the archive resolved it, nothing to mark.
      ProviderChange.find_by(id: change.id)&.update!(
        status: :failed,
        error_message: e.message,
        processed_at: Time.current
      )
    end
  end
end
