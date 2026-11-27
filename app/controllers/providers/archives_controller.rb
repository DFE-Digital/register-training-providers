class Providers::ArchivesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :update, by: -> { current_user.id }

  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :archive?
  end

  def update
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :archive?

    archived = @provider.with_lock do
      next false unless archivable?

      pre_archive_status = @provider.status
      record_archive(pre_archive_status)
      close_open_periods_and_archive

      true
    end

    if archived
      redirect_to(provider_path(@provider), flash: { success: "Provider archived" })
    else
      redirect_to(
        provider_path(@provider),
        flash: { alert: t("controllers.providers.archives.update.status_changed") }
      )
    end
  end

private

  def archivable?
    return false if @provider.discarded?
    return false if @provider.archived?

    @provider.status == ProviderStatusEnum::INACTIVE
  end

  def record_archive(previous_status)
    Providers::RecordStatusChange.call(
      provider: @provider,
      status_value: "archived",
      previous_status: previous_status,
      creator: current_user
    )
  end

  def close_open_periods_and_archive
    @provider.close_open_inactive_periods(ending_on: Time.zone.today)
    @provider.archive!
  end
end
