class Providers::DeletesController < CheckController
  def show
    @provider = Provider.find_by(uuid: params[:provider_id])
  end

  def destroy
    @provider = Provider.find_by(uuid: params[:provider_id])
    @provider.discard!
    redirect_to(providers_path, flash: { success: "Provider deleted" })
  end
end
