module AddressJourneyContext
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers

    attr_reader :provider, :context
  end

  def provider_creation_context?
    context == :create_provider
  end

  def existing_provider_context?
    context == :existing_provider
  end

  def edit_context?
    context == :edit
  end

  def journey_service
    @journey_service ||= Providers::CreationJourneyService.new(
      current_step: :address,
      provider: provider,
      goto_param: nil
    )
  end
end
