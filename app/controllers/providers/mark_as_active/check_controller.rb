class Providers::MarkAsActive::CheckController < CheckController
  helper_method :back_path
  helper_method :inactive_period

  def show
    authorize provider, :mark_as_active?
  end

  def update
    authorize provider, :mark_as_active?

    provider.save!

    redirect_to(provider_path(provider), flash: { success: "Provider updated" })
  end

private

  def provider
    @provider ||= current_user.load_temporary(Provider, id: params[:provider_id], purpose: :edit_provider)
  end

  def back_path
    provider_mark_as_inactive_reasons_path(provider)
  end

  def inactive_period
    provider.latest_complete_inactive_period
  end
end
