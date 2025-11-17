class Providers::DetailsController < CheckController
  helper_method :back_path

  def new
    # Validate previous steps from session
    onboarding_data = provider_session.load_onboarding
    if onboarding_data.nil? || Providers::IsTheProviderAccredited.new(onboarding_data).invalid?
      redirect_to new_provider_onboarding_path
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
      @provider.assign_attributes(provider_type_data)
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
          "legal_name", "ukprn", "urn", "code"
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
    params.expect(provider: [:provider_type, :accreditation_status, :operating_name, :ukprn, :code, :urn, :legal_name])
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
