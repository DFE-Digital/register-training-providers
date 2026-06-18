class Providers::DetailsController < CheckController
  helper_method :back_path

  def new
    # Validate previous steps from session
    onboarding_data = provider_session.load_onboarding
    onboarding_form = Providers::OnboardingForm.new(onboarding_data)
    if onboarding_data.nil? || onboarding_form.invalid?
      redirect_to new_provider_onboarding_path
      return
    end

    first_become_active_data = provider_session.load_first_become_active
    first_become_active_form = Providers::FirstBecomeActiveForm.new(first_become_active_data)
    if first_become_active_data.nil? || first_become_active_form.invalid?
      redirect_to new_provider_first_become_active_path
      return
    end

    is_provider_accredited_data = provider_session.load_is_provider_accredited
    if is_provider_accredited_data.nil? || Providers::IsTheProviderAccredited.new(is_provider_accredited_data).invalid?
      redirect_to new_provider_is_provider_accredited_path
      return
    end

    provider_type_data = provider_session.load_provider_type
    if provider_type_data.nil? || Providers::ProviderType.new(provider_type_data).invalid?
      redirect_to new_provider_type_path
      return
    end

    @provider = provider_session.load_provider

    # Only set provider_type attributes if this is a fresh provider (not loaded from session)
    if @provider.nil?
      @provider = Provider.new
      provider_attributes = provider_type_data.merge({ onboarded_at: onboarding_form.onboarded_at,
                                                       first_active_at: first_become_active_form.first_active_at })
      @provider.assign_attributes(provider_attributes)

    end

    render :new
  end

  def create
    @provider = provider_session.load_provider || Provider.new

    @provider.assign_attributes(create_new_provider_params)

    if @provider.valid?
      # Store relevant attributes as a plain hash, not all AR attributes which may include DB-specific fields
      provider_session.store_provider(
        @provider.attributes.slice(
          "provider_type", "accreditation_status", "operating_name",
          "legal_name", "ukprn", "urn", "code", "onboarded_at", "first_active_at"
        )
      )

      redirect_to journey_coordinator(:details, @provider).next_path
    else
      render :new
    end
  end

private

  def back_path
    journey_coordinator(:details, @provider).back_path
  end

  def create_new_provider_params
    params.expect(provider: [:provider_type,
                             :accreditation_status,
                             :operating_name,
                             :ukprn,
                             :code,
                             :urn,
                             :legal_name,
                             :onboarded_at,
                             :first_active_at])
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
