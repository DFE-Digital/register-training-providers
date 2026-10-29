module Providers
  class ApplyProviderChangeJob < ApplicationJob
    def perform(provider_change_id)
      change = ProviderChange.find_by(id: provider_change_id)
      return if change.blank?

      change.provider.with_lock do
        change = ProviderChange.find_by(id: provider_change_id)

        next if change.blank?
        next if change.completed? || change.failed?
        next if change.effective_on > Date.current
        next fail_change(change, "Provider is archived") if change.provider.archived?

        apply(change)
      end
    end

  private

    def apply(change)
      record_outcome(change) do
        status_change?(change) ? apply_status_change(change) : apply_attribute_change(change)
      end
    end

    def status_change?(change)
      change.attribute_name == "status"
    end

    def apply_status_change(change)
      Providers::ApplyStatusChangeService.call(
        provider: change.provider,
        new_status: change.value["status"],
        effective_on: change.effective_on,
        reasons: status_change_reasons(change)
      )
    end

    def status_change_reasons(change)
      ProviderStatusEnum.reason_labels_for(
        change.value["reason_ids"],
        change.value["other_reason"]
      )
    end

    def apply_attribute_change(change)
      change.provider.with_lock do
        next :archived if change.provider.archived?
        next :discarded if change.provider.discarded?

        # rubocop:disable Rails/SaveBang
        change.provider.update(change.attribute_name => change.value)
        # rubocop:enable Rails/SaveBang
      end
    end

    def record_outcome(change)
      applied = yield
      error_message = outcome_error_message(change, applied)

      change = ProviderChange.find_by(id: change.id)
      return unless change&.pending?

      change.update!(
        status: applied == true ? :completed : :failed,
        error_message: error_message,
        processed_at: Time.current
      )
    rescue StandardError => e
      record_failure(change, e)
    end

    def outcome_error_message(change, applied)
      case applied
      when :archived then "Provider was archived before the change could be applied"
      when :discarded then "Provider was discarded before the change could be applied"
      when false then change.provider.errors.full_messages.join(", ")
      end
    end

    def record_failure(change, error)
      change = ProviderChange.find_by(id: change.id)
      return unless change&.pending?

      fail_change(change, error.message)
    end

    def fail_change(change, message)
      change.update!(
        status: :failed,
        error_message: message,
        processed_at: Time.current
      )
    end
  end
end
