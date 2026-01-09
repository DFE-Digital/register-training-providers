module PartnershipJourneyController
  extend ActiveSupport::Concern

private

  def provider
    @provider ||= Provider.find(params[:provider_id])
  end

  def partnership_session
    @partnership_session ||= PartnershipJourney::SessionManager.new(session)
  end
end
