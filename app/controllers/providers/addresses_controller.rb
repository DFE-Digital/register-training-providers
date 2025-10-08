class Providers::AddressesController < ApplicationController
  def index
    authorize provider, :show?
    @addresses = policy_scope(provider.addresses)
  end
end
