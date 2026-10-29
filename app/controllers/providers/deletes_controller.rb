class Providers::DeletesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :destroy, by: -> { current_user.id }

  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :destroy?
  end

  def destroy
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :destroy?

    deleted = @provider.with_lock do
      next false unless @provider.archived?
      next false if @provider.discarded?

      @provider.discard!
      true
    end

    if deleted
      redirect_to(providers_path, flash: { success: "Provider deleted" })
    else
      redirect_to(
        providers_path,
        flash: { alert: t("controllers.providers.deletes.update.status_changed") }
      )
    end
  end
end
