class Providers::RestoresController < CheckController
  def show
    @provider = Provider.find_by(uuid: params[:provider_id])
  end

  def update
    @provider = Provider.find_by(uuid: params[:provider_id])
    @provider.restore!
    redirect_to(provider_path(@provider), flash: { success: "Provider restored" })
  end
end
