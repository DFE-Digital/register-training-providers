class Providers::OnboardingController < CheckController
  helper_method :back_path

  def new
    onboarding_data = provider_session.load_onboarding
    @form = Providers::IsTheProviderAccredited.new(onboarding_data || {})
  end

  def create
    @form = Providers::IsTheProviderAccredited.new(accreditation_status_params)

    if @form.valid?
      provider_session.store_onboarding(@form.attributes)

      redirect_to journey_coordinator(:onboarding, nil).next_path
    else
      render :new
    end
  end

private

  def back_path
    journey_coordinator(:onboarding, nil).back_path
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

  def accreditation_status_params
    params.expect(provider: [:accreditation_status])
  end
end
