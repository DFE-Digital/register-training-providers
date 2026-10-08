class Providers::DetailsController < CheckController
  helper_method :back_path

  def new
    return unless valid_session_data?

    @provider = provider_session.load_provider

    # Only derive attributes if this is a fresh provider (not loaded from session)
    if @provider.nil?
      @provider = Provider.new
      @provider.assign_attributes(session_provider_attributes)
    end

    authorize @provider

    render :new
  end

  def create
    @provider = provider_session.load_provider || Provider.new

    authorize @provider

    return unless valid_session_data?

    @provider.assign_attributes(provider_attributes)

    if @provider.valid?(:without_rotp_id)
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

  def valid_session_data?
    if provider_session.load_onboarding.nil? || onboarding_form.invalid?
      redirect_to new_provider_onboarding_path
      return false
    end

    if provider_session.load_first_become_active.nil? || first_become_active_form.invalid?
      redirect_to new_provider_first_become_active_path
      return false
    end

    if provider_session.load_is_provider_accredited.nil? ||
        Providers::IsTheProviderAccredited.new(provider_session.load_is_provider_accredited).invalid?
      redirect_to new_provider_is_the_provider_accredited_path
      return false
    end

    if provider_session.load_provider_type.nil? || Providers::ProviderType.new(provider_session.load_provider_type).invalid?
      redirect_to new_provider_type_path
      return false
    end

    true
  end

  def onboarding_form
    @onboarding_form ||= Providers::OnboardingForm.new(provider_session.load_onboarding)
  end

  def first_become_active_form
    @first_become_active_form ||= Providers::FirstBecomeActiveForm.new(provider_session.load_first_become_active)
  end

  def stored_provider_type_data
    @stored_provider_type_data ||= provider_session.load_provider_type || {}
  end

  def session_provider_attributes
    {
      provider_type: stored_provider_type_data["provider_type"],
      accreditation_status: stored_provider_type_data["accreditation_status"],
      onboarded_at: onboarding_form.onboarded_at || @provider&.onboarded_at,
      first_active_at: first_become_active_form.first_active_at || @provider&.first_active_at
    }
  end

  def provider_attributes
    session_provider_attributes.merge(create_new_provider_params)
  end

  def create_new_provider_params
    params.expect(provider: [:operating_name,
                             :ukprn,
                             :code,
                             :urn,
                             :legal_name])
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
