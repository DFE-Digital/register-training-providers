class Providers::MarkAsInactive::CheckController < CheckController
  helper_method :back_path

  def show
    authorize provider, :mark_as_inactive?
  end

  def update
    authorize provider, :mark_as_inactive?

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
end
