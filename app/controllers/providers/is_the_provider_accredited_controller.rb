class Providers::IsTheProviderAccreditedController < CheckController
  helper_method :back_path

  def new
    is_provider_accredited_data = provider_session.load_is_provider_accredited
    @form = Providers::IsTheProviderAccredited.new(is_provider_accredited_data || {})

    authorize @form
  end

  def create
    @form = Providers::IsTheProviderAccredited.new(is_the_provider_accredited_params)

    authorize @form

    if @form.valid?
      previous_data = provider_session.load_is_provider_accredited
      provider_session.store_is_provider_accredited(@form.attributes)
      clear_stale_provider_type(previous_data)

      redirect_to journey_coordinator(:is_the_provider_accredited, nil).next_path
    else
      render :new
    end
  end

private

  def clear_stale_provider_type(previous_data)
    return if previous_data.blank?
    return if previous_data["accreditation_status"] == @form.accreditation_status

    provider_session.clear_provider_type
    provider_session.clear_accreditation
  end

  def back_path
    journey_coordinator(:is_the_provider_accredited, nil).back_path
  end

  def journey_coordinator(current_step, provider)
    ProviderCreation::JourneyCoordinator.new(
      current_step: current_step,
      session_manager: provider_session,
      provider: provider
    )
  end

  def provider_session
    @provider_session ||= ProviderCreation::SessionManager.new(session)
  end

  def address_session
    @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
  end

  def is_the_provider_accredited_params
    params.expect(provider: [:accreditation_status])
  end
end
