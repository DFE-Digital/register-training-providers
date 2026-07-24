class Providers::ArchivesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :update, by: -> { current_user.id }

  def show
    @provider = Provider.find(params[:provider_id])
  end

  def update
    @provider = Provider.find(params[:provider_id])
    @provider.archive!
    redirect_to(provider_path(@provider), flash: { success: "Provider archived" })
  end
end
