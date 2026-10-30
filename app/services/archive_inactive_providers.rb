class ArchiveInactiveProviders
  include ServicePattern

  def self.age_to_archive_inactive_providers
    3.years.ago
  end

  def call
    Provider.inactive.find_each do |provider|
      next unless archivable?(provider)

      archive(provider)
    rescue StandardError => e
      log_archive_failure(provider, e)
    end
  end

private

  def archive(provider)
    provider.with_lock do
      next unless archivable?(provider)

      Providers::RecordStatusChange.call(
        provider: provider,
        status_value: "archived",
        previous_status: provider.status
      )

      provider.close_open_inactive_periods(ending_on: Time.zone.today)
      provider.archive!
    end
  end

  def archivable?(provider)
    return false if provider.discarded?
    return false if provider.archived?
    return false if provider.open_offboarded_period.present?

    period = provider.current_inactive_period

    return false if period.blank?

    ProviderStatusEnum.effective_period_start(period) <= self.class.age_to_archive_inactive_providers
  end

  def log_archive_failure(provider, error)
    Rails.logger.error(
      event: "provider_archive_failed",
      provider_id: provider.id,
      error_class: error.class.name,
      error_message: error.message
    )
  end
end
