module Providers
  module Partnerships
    class HistoricController < ApplicationController
      def index
        authorize provider, :show?

        @partnerships = policy_scope(provider.partnerships)
          .ended
          .includes(:provider, :accredited_provider, :partnership_types)
          .ordered_by_partner_and_date(provider)
      end
    end
  end
end
