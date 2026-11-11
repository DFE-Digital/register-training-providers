module Providers
  module Partnerships
    class EndsController < ApplicationController
      rate_limit to: 3, within: 3.minutes, only: :update, by: -> { current_user.id }

      def show
        authorize provider, :manage_partnerships?

        unless partnership.can_be_ended?
          return redirect_to provider_partnerships_path(provider),
                             flash: { alert: I18n.t("flash_message.alert.partnership.end_failed") }
        end

        setup_view_data
      end

      def update
        authorize provider, :manage_partnerships?

        if partnership.with_lock { partnership.end! }
          redirect_to provider_partnerships_path(provider),
                      flash: { success: I18n.t("flash_message.success.partnership.ended",
                                               name: other_partner.operating_name) }
        else
          redirect_to provider_partnerships_path(provider),
                      flash: { alert: I18n.t("flash_message.alert.partnership.end_failed") }
        end
      end

    private

      def partnership
        @partnership ||= provider.partnerships.kept.find(params[:partnership_id])
      end

      def provider
        @provider ||= Provider.kept.find(params[:provider_id])
      end

      def other_partner
        partnership.other_partner(provider)
      end

      def setup_view_data
        @page_title = "End partnership with #{other_partner.operating_name}?"
        @page_subtitle = "End partnership - #{provider.operating_name}"
        @page_caption = "End partnership - #{provider.operating_name}"
        @back_path = provider_partnerships_path(provider)
        @cancel_path = provider_partnerships_path(provider)
        @end_path = provider_partnership_end_path(partnership, provider_id: provider.id)
      end
    end
  end
end
