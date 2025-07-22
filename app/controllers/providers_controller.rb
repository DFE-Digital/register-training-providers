class ProvidersController < ApplicationController
  include Pagy::Backend
  include SummaryHelpers

  def index
    [Providers::IsTheProviderAccredited,
     Providers::ProviderType,
     Provider,].each do |form|
      current_user.clear_temporary(form, purpose: :create_provider)
    end

    @pagy, providers = pagy(Provider.kept.order_by_operating_name)

    @govuk_summary_cards = provider_summary_cards(providers)
  end
end
