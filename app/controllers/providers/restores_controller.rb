class Providers::RestoresController < CheckController
  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :restore?
  end

  def update
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :restore?

    restored = @provider.with_lock do
      next false unless @provider.archived?
      next false if @provider.discarded?

      pre_restore_status = @provider.status
      reopen_previous_period(@provider)
      @provider.restore!
      record_restore(pre_restore_status)

      true
    end

    if restored
      redirect_to(provider_path(@provider), flash: { success: "Provider restored" })
    else
      redirect_to(
        provider_path(@provider),
        flash: { alert: t("controllers.providers.restores.update.status_changed") }
      )
    end
  end

private

  def record_restore(previous_status)
    Providers::RecordStatusChange.call(
      provider: @provider,
      status_value: @provider.status,
      previous_status: previous_status,
      creator: current_user
    )
  end

  def reopen_previous_period(provider)
    archive_change = provider.provider_changes
      .completed
      .for_attribute("status")
      .where("value->>'status' = 'archived'")
      .order(effective_on: :desc, created_at: :desc)
      .first

    previous_status = archive_change&.value&.dig("previous_status")
    return unless [ProviderStatusEnum::INACTIVE, ProviderStatusEnum::OFFBOARDED].include?(previous_status)

    periods = provider.inactive_periods.map(&:dup)
    period = periods
      .select { |candidate| candidate["end_date"].present? }
      .max_by { |candidate| candidate["start_date"] }
    return if period.blank?
    return unless period["end_date"].to_date >= archive_change.effective_on - 1.day
    return unless (period["offboarded"] == true) == (previous_status == ProviderStatusEnum::OFFBOARDED)

    period["end_date"] = nil
    provider.inactive_periods = periods
  end
end
