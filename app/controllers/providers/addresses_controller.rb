class Providers::AddressesController < ApplicationController
  def index
    authorize provider.addresses.build
    @addresses = policy_scope(provider.addresses)
  end
end
