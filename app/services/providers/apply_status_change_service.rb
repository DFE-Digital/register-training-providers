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
      provider.with_lock do
        next false if discarded?
        next true if already_in_new_status?
        next false unless valid_transition?

        apply_transition
      end
    end

  private

    attr_reader :provider, :new_status, :effective_on, :reasons

    def apply_transition
      provider.close_open_inactive_periods(ending_on: effective_on)
      add_new_period if new_status != ProviderStatusEnum::ACTIVE

      # rubocop:disable Rails/SaveBang
      provider.save
      # rubocop:enable Rails/SaveBang
    end

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
      earliest_date = ProviderStatusEnum.earliest_valid_date(provider)

      return true if earliest_date.blank? || effective_on.blank? || effective_on >= earliest_date

      provider.errors.add(:base,
                          "The date cannot be before the provider was onboarded " \
                          "(#{earliest_date.to_fs(:govuk)})")
      false
    end

    def add_new_period
      period = { "start_date" => effective_on, "end_date" => nil }
      period["offboarded"] = true if new_status == ProviderStatusEnum::OFFBOARDED
      period["reasons_for_inactive"] = reasons if reasons.present?

      provider.inactive_periods = provider.inactive_periods + [period]
    end
  end
end
