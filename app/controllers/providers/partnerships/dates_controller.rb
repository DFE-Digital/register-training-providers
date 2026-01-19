module Providers
  module Partnerships
    class DatesController < ApplicationController
      include PartnershipJourneyController

      DateValues = Struct.new(:start_date, :end_date, keyword_init: true)

      def new
        partnership_data = partnership_session.load_partnership
        @form = build_form_from_session(partnership_data)

        setup_view_data(:new)
      end

      def edit
        @partnership = provider.partnerships.kept.find(params[:id])
        authorize @partnership

        partnership_data = partnership_session.load_partnership
        @form = build_form_for_edit(partnership_data, @partnership)

        setup_view_data(:edit)
        render :new
      end

      def create
        @form = ::Partnerships::DatesForm.new(dates_form_params)

        partnership_attributes = partnership_session.load_partnership

        unless partnership_attributes
          redirect_to provider_new_partnership_find_path(provider)
          return
        end

        if @form.valid?
          partnership_session.store_partnership(partnership_attributes.merge(@form.attributes))

          redirect_to next_path(:new)
        else
          setup_view_data(:new)
          render :new
        end
      end

      def update
        @partnership = provider.partnerships.kept.find(params[:id])
        authorize @partnership

        @form = ::Partnerships::DatesForm.new(dates_form_params)

        partnership_data = partnership_session.load_partnership || {}

        if @form.valid?
          partnership_session.store_partnership(partnership_data.merge(@form.attributes))

          redirect_to next_path(:edit)
        else
          setup_view_data(:edit)
          render :new
        end
      end

    private

      def dates_form_params
        params.expect(dates: [*::Partnerships::DatesForm::PARAM_CONVERSION.keys])
          .transform_keys { |k| ::Partnerships::DatesForm::PARAM_CONVERSION.fetch(k, k) }
      end

      def next_path(context)
        if context == :edit
          provider_edit_partnership_academic_cycles_path(@partnership, provider_id: provider.id, goto: params[:goto])
        elsif params[:goto] == "confirm"
          provider_new_partnership_confirm_path(provider)
        else
          provider_new_partnership_academic_cycles_path(provider)
        end
      end

      def back_path(context)
        if context == :edit && params[:goto] == "confirm"
          provider_partnership_check_path(@partnership, provider_id: provider.id)
        elsif context == :edit
          provider_partnerships_path(provider)
        elsif params[:goto] == "confirm"
          provider_new_partnership_confirm_path(provider)
        else
          provider_new_partnership_find_path(provider)
        end
      end

      def build_form_from_session(partnership_data)
        return ::Partnerships::DatesForm.new unless partnership_data&.dig(:start_date)

        dates_object = DateValues.new(
          start_date: partnership_data[:start_date],
          end_date: partnership_data[:end_date]
        )
        ::Partnerships::DatesForm.from_dates(dates_object)
      end

      def build_form_for_edit(partnership_data, partnership)
        if partnership_data&.dig(:start_date)
          build_form_from_session(partnership_data)
        else
          dates_object = DateValues.new(
            start_date: partnership.duration.begin,
            end_date: partnership.duration.end.is_a?(Date) ? partnership.duration.end : nil
          )
          ::Partnerships::DatesForm.from_dates(dates_object)
        end
      end

      def form_url(context)
        if context == :edit
          provider_edit_partnership_dates_path(@partnership, provider_id: provider.id, goto: params[:goto])
        else
          provider_partnership_dates_path(provider, goto: params[:goto])
        end
      end

      def cancel_path
        provider_partnerships_path(provider)
      end

      def page_caption(context)
        if context == :edit
          provider.operating_name.to_s
        else
          "Add partnership - #{provider.operating_name}"
        end
      end

      def setup_view_data(context)
        @back_path = back_path(context)
        @form_url = form_url(context)
        @form_method = context == :edit ? :patch : :post
        @cancel_path = cancel_path
        @page_title = "Partnership dates"
        @page_subtitle = provider.operating_name.to_s
        @page_caption = page_caption(context)
      end
    end
  end
end
