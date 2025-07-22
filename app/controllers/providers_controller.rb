class ProvidersController < ApplicationController
  def index
    [Providers::IsTheProviderAccredited,
     Providers::ProviderType,
     Provider,].each do |form|
      current_user.clear_temporary(form, purpose: :create_provider)
    end
  end
end
