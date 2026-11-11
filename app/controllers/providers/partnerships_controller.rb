module Providers
  class PartnershipsController < ApplicationController
    def index
      @partnerships = policy_scope(provider.partnerships)
        .includes(:partnership_types, :academic_years)
        .ordered_by_partner_and_date(provider)

      authorize provider
    end
  end
end
