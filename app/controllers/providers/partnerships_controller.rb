module Providers
  class PartnershipsController < ApplicationController
    def index
      @partnerships = policy_scope(provider.partnerships)
        .current_or_scheduled
        .includes(:provider, :accredited_provider, :partnership_types, :academic_years)
        .ordered_by_partner_and_date(provider)

      @historic_partnerships_count = policy_scope(provider.partnerships).ended.count

      authorize provider
    end
  end
end
