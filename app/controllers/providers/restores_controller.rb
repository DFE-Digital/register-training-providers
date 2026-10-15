class Providers::RestoresController < CheckController
  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :restore?
  end

  def update
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :restore?

    @provider.with_lock do
      # with_lock re-loads the row, so archived? is re-checked against the
      # committed state: two overlapping writers serialise on the row lock
      # and only the first (still-archived) writer restores.
      next unless @provider.archived?

      # Capture the pre-restore status first: restore! clears archived_at, so
      # re-reading provider.status afterwards would make the status-change
      # baseline record the restored status instead of the Archived state the
      # provider actually held.
      pre_restore_status = @provider.status
      @provider.restore!
      Providers::RecordStatusChange.call(
        provider: @provider,
        status_value: @provider.status,
        previous_status: pre_restore_status,
        creator: current_user
      )
    end

    redirect_to(provider_path(@provider), flash: { success: "Provider restored" })
  end
end
