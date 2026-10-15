class Providers::ArchivesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :update, by: -> { current_user.id }

  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider
  end

  def update
    @provider = Provider.find(params[:provider_id])
    authorize @provider

    @provider.with_lock do
      # with_lock re-loads the row, so archived? is re-checked against the
      # committed state: two overlapping writers serialise on the row lock
      # and only the first records and archives.
      next if @provider.archived?

      # Record first so the status-change baseline captures the pre-archive
      # status: closing the open period below clears the open-period-derived
      # status, so a baseline recorded afterwards would read "active".
      Providers::RecordStatusChange.call(provider: @provider, status_value: "archived", creator: current_user)

      close_open_periods
      @provider.archive!
    end

    redirect_to(provider_path(@provider), flash: { success: "Provider archived" })
  end

private

  # Archiving ends the provider's presence on the register, so any period still
  # open — inactive or off-boarded — must be closed: otherwise the provider
  # page renders an open-ended period for an archived record, `Provider.inactive`
  # keeps matching it and `active_in_academic_year?` keeps counting it. The
  # period ends the day before the archive takes effect, the exclusive
  # convention used by ApplyStatusChangeService#close_open_periods and
  # ArchiveInactiveProviders. Unlike the nightly sweep, which must not override
  # a deliberate off-boarding, a manual archive is itself the office's act, so
  # it closes an open off-boarded period too. `max` guards a period that began
  # today so it never ends before it started.
  def close_open_periods
    @provider.inactive_periods = @provider.inactive_periods.map do |period|
      next period unless period["end_date"].nil?

      period.merge("end_date" => [Time.zone.yesterday, period["start_date"].to_date].max)
    end
  end
end
