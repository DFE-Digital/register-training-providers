class Providers::DeletesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :destroy, by: -> { current_user.id }

  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :destroy?
  end

  def destroy
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :destroy?

    @provider.with_lock do
      next unless @provider.archived?
      next if @provider.discarded?

      @provider.discard!
    end

    redirect_to(providers_path, flash: { success: "Provider deleted" })
  end
end
