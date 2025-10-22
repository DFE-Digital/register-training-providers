class Providers::ContactsController < ApplicationController
  def index
    authorize provider, :show?
    @contacts = policy_scope(provider.contacts)
  end

private

  def provider
    @provider ||= Provider.find(params[:provider_id])
  end
end
