class Providers::RestoresController < CheckController
  def show
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :restore?
  end

  def update
    @provider = Provider.find(params[:provider_id])
    authorize @provider, :restore?
    @provider.restore!
    redirect_to(provider_path(@provider), flash: { success: "Provider restored" })
  end
end
