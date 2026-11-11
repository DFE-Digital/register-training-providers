module Providers
  module Partnerships
    class CheckController < ApplicationController
      include PartnershipJourneyController

      def show
        @partnership = provider.partnerships.kept.find(params[:id])
        authorize @partnership

        partnership_data = partnership_session.load_partnership
        @form = build_partnership_form_for_edit(partnership_data, @partnership)

        if @form.invalid?
          redirect_to provider_edit_partnership_dates_path(@partnership, provider_id: provider.id)
          return
        end

        setup_view_data
      end

      def update
        @partnership = provider.partnerships.kept.find(params[:id])
        authorize @partnership

        partnership_data = partnership_session.load_partnership
        @form = build_partnership_form_for_edit(partnership_data, @partnership)

        if @partnership.update(@form.to_partnership_attributes)
          partnership_session.clear!
          redirect_to provider_partnerships_path(provider),
                      flash: { success: I18n.t("flash_message.success.check.partnership.update") }
        else
          redirect_to provider_edit_partnership_dates_path(@partnership, provider_id: provider.id),
                      flash: { alert: partnership_save_failure_message(@partnership) }
        end
      end

    private

      def partnership_save_failure_message(partnership)
        type_messages = partnership.partnership_types.flat_map { |type| type.errors[:partnership_type] }
        messages = type_messages.presence || partnership.errors.full_messages

        messages.to_sentence.presence ||
          I18n.t("flash_message.alert.check.partnership.save_failed")
      end

      def back_path
        provider_edit_partnership_academic_years_path(@partnership, provider_id: provider.id)
      end

      def save_path
        provider_partnership_check_path(@partnership, provider_id: provider.id)
      end

      def cancel_path
        provider_partnerships_path(provider)
      end

      def build_partnership_form_for_edit(partnership_data, partnership)
        if partnership_data&.dig(:start_date)
          ::PartnershipForm.new(partnership_data.merge(
                                  provider_id: partnership.provider_id,
                                  accredited_provider_id: partnership.accredited_provider_id
                                ))
        else
          ::PartnershipForm.from_partnership(partnership)
        end
      end

      def setup_view_data
        @back_path = back_path
        @save_path = save_path
        @cancel_path = cancel_path
        @save_button_text = "Save partnership"
        @provider_accredited = provider.accredited?
        @change_paths = build_change_paths
        @form_method = :patch
        @page_subtitle = provider.operating_name.to_s
        @page_caption = provider.operating_name.to_s
      end

      def build_change_paths
        {
          dates: provider_edit_partnership_dates_path(@partnership, provider_id: provider.id, goto: "confirm"),
          academic_years: provider_edit_partnership_academic_years_path(
            @partnership, provider_id: provider.id, goto: "confirm"
          )
        }
      end
    end
  end
end
