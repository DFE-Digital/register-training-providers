module Providers
  module Partnerships
    class FindController < ApplicationController
      include PartnershipJourneyController

      def new
        @form = ::Partnerships::FindForm.new

        setup_view_data
      end

      def create
        @form = ::Partnerships::FindForm.new(
          partner_id: params.dig(:find, :partner_id),
        )

        if @form.valid?
          partnership_session.store_partnership(
            partner_id: params.dig(:find, :partner_id),
            training_partner_search: provider.accredited?,
          )

          redirect_to dates_path
        else
          setup_view_data
          render :new
        end
      end

    private

      def dates_path
        provider_new_partnership_dates_path(provider)
      end

      def back_path
        provider_partnerships_path(provider)
      end

      def form_url
        provider_partnership_find_path(provider)
      end

      def cancel_path
        provider_partnerships_path(provider)
      end

      def page_subtitle
        provider.operating_name.to_s
      end

      def page_caption
        "Add partnership - #{@provider.operating_name}"
      end

      def setup_view_data
        @back_path = back_path
        @form_url = form_url
        @cancel_path = cancel_path
        @page_title = "Enter training partner name, code, UKPRN or URN"
        @page_subtitle = page_subtitle
        @page_caption = page_caption
      end
    end
  end
end
