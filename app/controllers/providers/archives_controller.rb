class Providers::ArchivesController < CheckController
  def show
    @provider = Provider.find(params[:provider_id])
  end

  def update
    @provider = Provider.find(params[:provider_id])
    @provider.archive!
    redirect_to(provider_path(@provider), flash: { success: "Provider archived" })
  end
end
