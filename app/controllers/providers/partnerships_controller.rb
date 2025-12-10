class Providers::PartnershipsController < ApplicationController
  def index
    authorize provider, :show?
    @partnerships = policy_scope(provider.partnerships)
  end
end
