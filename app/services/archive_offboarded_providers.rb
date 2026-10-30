class ArchiveOffboardedProviders
  include ServicePattern

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
        previous_status: provider.status,
        effective_on: academic_year_start
      )

      provider.close_open_inactive_periods(ending_on: academic_year_start)
      provider.archive!(archived_at: academic_year_start)
    end
  end

  def archivable?(provider)
    return false if provider.discarded?
    return false if provider.archived?

    period = provider.open_offboarded_period

    return false if period.blank?

    ProviderStatusEnum.effective_period_start(period) < academic_year_start
  end

  def log_archive_failure(provider, error)
    Rails.logger.error(
      event: "provider_archive_failed",
      provider_id: provider.id,
      error_class: error.class.name,
      error_message: error.message
    )
  end

  def academic_year_start
    @academic_year_start ||= AcademicYear.start_date_for(AcademicYearCalculator.current_academic_year)
  end
end
