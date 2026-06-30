class Providers::OnboardingController < CheckController
  helper_method :back_path

  def new
    onboarding_data = provider_session.load_onboarding
    @form = Providers::OnboardingForm.new(onboarding_data || {})
  end

  def create
    @form = Providers::OnboardingForm.new(onboarding_params)

    if @form.valid?
      provider_session.store_onboarding(@form.attributes)

      if from_check?
        provider = provider_session.load_provider

        provider_attributes = { onboarded_at: @form.onboarded_at }

        provider.assign_attributes(provider_attributes)

        provider_session.store_provider(
          provider.attributes.slice(
            "provider_type", "accreditation_status", "operating_name",
            "legal_name", "ukprn", "urn", "code", "onboarded_at", "first_active_at"
          )
        )
      end

      redirect_to journey_coordinator(:onboarding, nil).next_path
    else
      render :new
    end
  end

private

  def from_check?
    params[:goto] == "confirm"
  end

  def back_path
    journey_coordinator(:onboarding, nil).back_path
  end

  def journey_coordinator(current_step, provider)
    ProviderCreation::JourneyCoordinator.new(
      current_step: current_step,
      session_manager: provider_session,
      provider: provider,
      from_check: from_check?
    )
  end

  def provider_session
    @provider_session ||= ProviderCreation::SessionManager.new(session)
  end

  def address_session
    @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
  end

  def onboarding_params
    params.expect(provider: [*Providers::OnboardingForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| Providers::OnboardingForm::PARAM_CONVERSION.fetch(k, k) }
  end
end
