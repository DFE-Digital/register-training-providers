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

        setup_view_data(:edit)
      end

      def new
        partnership_data = partnership_session.load_partnership

        unless partnership_data
          redirect_to provider_new_partnership_find_path(provider)
          return
        end

        @form = build_form_from_session(partnership_data)

        if @form.invalid?
          redirect_to provider_new_partnership_find_path(provider, goto: "confirm")
          return
        end

        setup_view_data(:new)
      end

      def create
        partnership_data = partnership_session.load_partnership

        unless partnership_data
          redirect_to provider_new_partnership_find_path(provider)
          return
        end

        @form = build_form_from_session(partnership_data)

        partnership = provider.partnerships.build(@form.to_partnership_attributes)
        authorize partnership

        if partnership.save
          partnership_session.clear!
          redirect_to provider_partnerships_path(provider),
                      flash: { success: I18n.t("flash_message.success.check.partnership.add") }
        else
          redirect_to provider_new_partnership_find_path(provider, goto: "confirm")
        end
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
          setup_view_data(:edit)
          render :new
        end
      end

    private

      def edit_context?
        params[:id].present?
      end

      def back_path(context)
        if context == :edit
          provider_edit_partnership_academic_cycles_path(@partnership, provider_id: provider.id)
        else
          provider_new_partnership_academic_cycles_path(provider, goto: "confirm")
        end
      end

      def save_path
        if edit_context?
          provider_partnership_check_path(@partnership, provider_id: provider.id)
        else
          provider_partnership_confirm_path(provider)
        end
      end

      def cancel_path
        provider_partnerships_path(provider)
      end

      def set_partners(partnership_data)
        if provider.accredited?
          { provider_id: partnership_data[:partner_id], accredited_provider_id: provider.id }
        else
          { accredited_provider_id: partnership_data[:partner_id], provider_id: provider.id }
        end
      end

      def build_partnership_form_for_edit(partnership_data, partnership)
        if partnership_data&.dig(:start_date)
          # Session has dates from edit flow - merge with partnership's partner IDs
          ::PartnershipForm.new(partnership_data.merge(
                                  provider_id: partnership.provider_id,
                                  accredited_provider_id: partnership.accredited_provider_id
                                ))
        else
          # No session data - load entirely from partnership
          ::PartnershipForm.from_partnership(partnership)
        end
      end

      def build_form_from_session(partnership_data)
        form_attrs = partnership_data.except(:partner_id, :training_partner_search)
        ::PartnershipForm.new(form_attrs.merge(set_partners(partnership_data)))
      end

      def setup_view_data(context)
        @back_path = back_path(context)
        @save_path = save_path
        @cancel_path = cancel_path
        @save_button_text = "Save partnership"
        @provider_accredited = provider.accredited?
        @change_paths = build_change_paths(context)

        if context == :edit
          @form_method = :patch
          @page_subtitle = provider.operating_name.to_s
          @page_caption = provider.operating_name.to_s
        else
          @form_method = :post
          @page_subtitle = "Add partnership - #{provider.operating_name}"
          @page_caption = "Add partnership - #{provider.operating_name}"
        end
      end

      def build_change_paths(context)
        if context == :edit
          # Edit flow: only dates and academic years are changeable (partner locked)
          {
            dates: provider_edit_partnership_dates_path(@partnership, provider_id: provider.id, goto: "confirm"),
            academic_cycles: provider_edit_partnership_academic_cycles_path(
              @partnership, provider_id: provider.id, goto: "confirm"
            )
          }
        else
          # Add flow: all fields changeable
          {
            partner: provider_new_partnership_find_path(provider, goto: "confirm"),
            dates: provider_new_partnership_dates_path(provider, goto: "confirm"),
            academic_cycles: provider_new_partnership_academic_cycles_path(provider, goto: "confirm")
          }
        end
      end
    end
  end
end
