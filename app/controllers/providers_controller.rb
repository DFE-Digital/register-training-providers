class ProvidersController < ApplicationController
  include Pagy::Backend

  def index
    [Providers::IsTheProviderAccredited,
     Providers::ProviderType,
     Provider,].each do |form|
      current_user.clear_temporary(form, purpose: :create_provider)
    end

    @pagy, @records = pagy(Provider.kept.order_by_operating_name)
  end
end
