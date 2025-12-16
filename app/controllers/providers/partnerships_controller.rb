class Providers::PartnershipsController < ApplicationController
  def index
    @partnerships = policy_scope(provider.partnerships)
  end
end
