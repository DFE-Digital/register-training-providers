module Providers
  class PartnershipsController < ApplicationController
    def index
      @partnerships = policy_scope(provider.partnerships).ordered_by_partner_and_date(provider)
    end
  end
end
