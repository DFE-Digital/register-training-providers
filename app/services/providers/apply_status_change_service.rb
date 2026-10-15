module Providers
  class ApplyStatusChangeService
    include ServicePattern

    def initialize(provider:, new_status:, effective_on:, reasons: [])
      @provider = provider
      @new_status = new_status.to_s
      @effective_on = effective_on
      @reasons = reasons
    end

    def call
      return false if discarded?

      return true if already_in_new_status?
      return false unless valid_transition?

      provider.with_lock do
        # with_lock implicitly re-loads the row, so a concurrent discard may
        # have landed while we waited for the lock. A soft-deleted provider is
        # terminal — the rest of the app excludes discarded records — so
        # applying the change would mutate a record the office has deleted.
        # Re-check against the locked row before any period mutation.
        next false if discarded?

        # with_lock implicitly re-loads the row, so a concurrent applier may
        # have already applied / invalidated this change while we waited for
        # the lock. Re-run the checks against the locked state before any
        # period mutation.
        next true if already_in_new_status?
        next false unless valid_transition?

        close_open_periods
        add_new_period if new_status != ProviderStatusEnum::ACTIVE

        # rubocop:disable Rails/SaveBang -- soft-fail so callers can mark the change :failed
        # instead of raising on providers that no longer pass today's validations
        provider.save
        # rubocop:enable Rails/SaveBang
      end
    end

  private

    attr_reader :provider, :new_status, :effective_on, :reasons

    def discarded?
      return false unless provider.discarded?

      provider.errors.add(:base, "Provider was discarded before the change could be applied")
      true
    end

    def already_in_new_status?
      provider.status == new_status
    end

    def valid_transition?
      return false unless transition_allowed?
      return false if effective_on.blank?
      return false unless closing_dates_are_valid?

      true
    end

    def transition_allowed?
      return true if provider.transitionable_status?(new_status)

      provider.errors.add(:base,
                          "Status cannot change from #{provider.status} to #{new_status}")
      false
    end

    def closing_dates_are_valid?
      return false unless effective_on_after_the_provider_existed?

      conflicting_period = ProviderStatusEnum.period_conflicting_with_date(provider.inactive_periods, effective_on)

      return true if conflicting_period.blank?

      provider.errors.add(:base,
                          "The date cannot be within or before the period " \
                          "(#{conflicting_period["start_date"].to_date.to_fs(:govuk)})")
      false
    end

    def effective_on_after_the_provider_existed?
      # Shared rule from ProviderStatusEnum.earliest_valid_date — the wizard
      # step and the apply path must accept or reject the same dates.
      earliest_date = ProviderStatusEnum.earliest_valid_date(provider)

      return true if earliest_date.blank? || effective_on.blank? || effective_on >= earliest_date

      provider.errors.add(:base,
                          "The date cannot be before the provider was onboarded " \
                          "(#{earliest_date.to_fs(:govuk)})")
      false
    end

    def close_open_periods
      provider.inactive_periods = provider.inactive_periods.map do |period|
        next period unless period["end_date"].nil?

        # The period ends the day before the new status takes effect: the
        # provider holds its new status from `effective_on`, so it is no
        # longer inactive on that day. This matches the history rendering
        # (ProviderChangeHelper#change_period_end) and stops a provider
        # reactivated on an academic year's first day from counting as
        # inactive for that year (Provider#active_in_academic_year?).
        # `max` guards a same-day transition so the period never ends
        # before it starts.
        period.merge("end_date" => [effective_on - 1.day, period["start_date"].to_date].max)
      end
    end

    def add_new_period
      period = { "start_date" => effective_on, "end_date" => nil }
      period["offboarded"] = true if new_status == ProviderStatusEnum::OFFBOARDED
      period["reasons_for_inactive"] = reasons if reasons.present?

      provider.inactive_periods = provider.inactive_periods + [period]
    end
  end
end
