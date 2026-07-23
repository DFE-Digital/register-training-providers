class Providers::DeletesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :destroy, by: -> { current_user.id }

  def show
    @provider = Provider.find(params[:provider_id])
  end

  def destroy
    @provider = Provider.find(params[:provider_id])
    @provider.discard!
    redirect_to(providers_path, flash: { success: "Provider deleted" })
  end
end
