class Providers::FirstBecomeActiveController < CheckController
  helper_method :back_path

  def new
    onboarding_data = provider_session.load_onboarding

    if onboarding_data.nil?
      redirect_to new_provider_onboarding_path
      return
    end

    onboarding_form = Providers::OnboardingForm.new(onboarding_data)
    if onboarding_form.invalid?
      redirect_to new_provider_onboarding_path
      return
    end

    first_become_active_data = provider_session.load_first_become_active
    @form = Providers::FirstBecomeActiveForm.new(first_become_active_data || {})

    @form.assign_attributes({ onboarded_at: onboarding_form.onboarded_at })

    render :new
  end

  def create
    @form = Providers::FirstBecomeActiveForm.new(first_become_active_params)

    if @form.valid?
      provider_session.store_first_become_active(@form.attributes)

      if from_check?
        provider = provider_session.load_provider
        provider_attributes = { first_active_at: @form.first_active_at }

        provider.assign_attributes(provider_attributes)

        provider_session.store_provider(
          provider.attributes.slice(
            "provider_type", "accreditation_status", "operating_name",
            "legal_name", "ukprn", "urn", "code", "onboarded_at", "first_active_at"
          )
        )
      end

      redirect_to journey_coordinator(:first_become_active, nil).next_path
    else
      render :new
    end
  end

private

  def back_path
    journey_coordinator(:first_become_active, nil).back_path
  end

  def journey_coordinator(current_step, provider)
    ProviderCreation::JourneyCoordinator.new(
      current_step: current_step,
      session_manager: provider_session,
      provider: provider,
      from_check: from_check?
    )
  end

  def from_check?
    params[:goto] == "confirm"
  end

  def provider_session
    @provider_session ||= ProviderCreation::SessionManager.new(session)
  end

  def address_session
    @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
  end

  def first_become_active_params
    params.expect(provider: [*Providers::FirstBecomeActiveForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| Providers::FirstBecomeActiveForm::PARAM_CONVERSION.fetch(k, k) }
  end
end
