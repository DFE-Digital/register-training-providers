class Providers::DeletesController < CheckController
  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider
  end

  def destroy
    @provider = Provider.find(params[:provider_id])
    authorize @provider
    @provider.discard!
    redirect_to(providers_path, flash: { success: "Provider deleted" })
  end
end
