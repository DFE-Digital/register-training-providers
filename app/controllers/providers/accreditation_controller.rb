class Providers::AccreditationController < CheckController
  helper_method :back_path

  def new
    provider_type_data = provider_session.load_provider_type

    if provider_type_data.nil?
      redirect_to new_provider_type_path
      return
    end

    provider_type = Providers::ProviderType.new(provider_type_data)
    if provider_type.invalid?
      redirect_to new_provider_type_path
      return
    end

    unless provider_type.accredited?
      redirect_to new_provider_confirm_path
      return
    end

    provider = provider_session.load_provider

    if provider.nil? || provider.invalid?
      redirect_to new_provider_details_path
      return
    end

    accreditation_data = provider_session.load_accreditation
    @form = AccreditationForm.new(accreditation_data || {})
    @form.provider_creation_mode = true
    @form.provider_id = provider.id
    @form.provider_type = provider.provider_type

    render :new
  end

  def create
    @form = AccreditationForm.new(create_accreditation_params)
    @form.provider_creation_mode = true

    provider = provider_session.load_provider
    @form.provider_id = provider&.id
    @form.provider_type = provider&.provider_type

    if @form.valid?
      provider_session.store_accreditation(@form.attributes)

      redirect_to journey_coordinator(:accreditation, provider).next_path
    else
      render :new
    end
  end

private

  def back_path
    provider = provider_session.load_provider
    journey_coordinator(:accreditation, provider).back_path
  end

  def create_accreditation_params
    params.expect(accreditation: [:number, *AccreditationForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| AccreditationForm::PARAM_CONVERSION.fetch(k, k) }
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
