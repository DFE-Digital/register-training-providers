class Providers::TypeController < CheckController
  helper_method :back_path

  def new
    is_the_provider_accredited_data = provider_session.load_is_provider_accredited

    if is_the_provider_accredited_data.nil?
      redirect_to new_provider_is_the_provider_accredited_path
      return
    end

    is_the_provider_accredited_form = Providers::IsTheProviderAccredited.new(is_the_provider_accredited_data)
    if is_the_provider_accredited_form.invalid?
      redirect_to new_provider_is_the_provider_accredited_path
      return
    end

    provider_type_data = provider_session.load_provider_type
    @form = Providers::ProviderType.new(provider_type_data || {})

    authorize @form

    @form.assign_attributes(is_the_provider_accredited_data)

    render :new
  end

  def create
    @form = Providers::ProviderType.new(provider_type_params)

    authorize @form

    is_the_provider_accredited_data = provider_session.load_is_provider_accredited

    if is_the_provider_accredited_data.nil? ||
        Providers::IsTheProviderAccredited.new(is_the_provider_accredited_data).invalid?
      redirect_to new_provider_is_the_provider_accredited_path
      return
    end

    @form.assign_attributes(is_the_provider_accredited_data)

    if @form.valid?
      provider_session.store_provider_type(@form.attributes)

      redirect_to journey_coordinator(:type, nil).next_path
    else
      render :new
    end
  end

private

  def back_path
    journey_coordinator(:type, nil).back_path
  end

  def provider_type_params
    params.fetch(:provider, {}).permit(:provider_type)
  end

  def journey_coordinator(current_step, provider)
    ProviderCreation::JourneyCoordinator.new(
      current_step: current_step,
      session_manager: provider_session,
      provider: provider,
      from_check: params[:goto] == "confirm"
    )
  end

  def provider_session
    @provider_session ||= ProviderCreation::SessionManager.new(session)
  end
end
