module AddressJourneyController
  extend ActiveSupport::Concern
  include DebuggerParamHelper

private

  def provider
    @provider ||= if params[:provider_id]
                    Provider.find(params[:provider_id])
                  else
                    provider_session.load_provider || Provider.new
                  end
  end

  def journey_context
    return :imported_data if debug_mode?

    params[:provider_id].present? ? :manage : :setup
  end

  def setup_context?
    journey_context == :setup
  end

  def imported_data_context?
    journey_context == :imported_data
  end

  def address_session
    context = journey_context
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
