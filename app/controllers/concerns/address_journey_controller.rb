module AddressJourneyController
  extend ActiveSupport::Concern

private

  def provider
    @provider ||= if params[:provider_id]
                    Provider.find(params[:provider_id])
                  else
                    provider_session.load_provider || Provider.new
                  end
  end

  def setup_context?
    params[:provider_id].blank?
  end

  def address_session
    context = setup_context? ? :setup : :manage
    @address_session ||= AddressJourney::SessionManager.new(session, context:)
  end

  def provider_session
    @provider_session ||= ProviderCreation::SessionManager.new(session)
  end

  def journey_coordinator(current_step)
    @journey_coordinator ||= ProviderCreation::JourneyCoordinator.new(
      current_step: current_step,
      session_manager: provider_session,
      provider: provider,
      from_check: params[:goto] == "confirm",
      address_session: address_session,
      from_select: params[:from] == "select"
    )
  end
end
