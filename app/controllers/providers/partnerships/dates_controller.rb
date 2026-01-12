module Providers
  module Partnerships
    class DatesController < ApplicationController
      include PartnershipJourneyController

      DateValues = Struct.new(:start_date, :end_date, keyword_init: true)

      def new
        partnership_data = partnership_session.load_partnership
        @form = build_form_from_session(partnership_data)

        setup_view_data
      end

      def create
        @form = ::Partnerships::DatesForm.new(dates_form_params)

        partnership_attributes = partnership_session.load_partnership

        if @form.valid?
          partnership_session.store_partnership(partnership_attributes.merge(@form.attributes))

          redirect_to academic_cycles_path
        else
          setup_view_data
          render :new
        end
      end

    private

      def dates_form_params
        params.expect(dates: [*::Partnerships::DatesForm::PARAM_CONVERSION.keys])
          .transform_keys { |k| ::Partnerships::DatesForm::PARAM_CONVERSION.fetch(k, k) }
      end

      def academic_cycles_path
        return provider_new_partnership_confirm_path(provider) if params[:goto] == "confirm"

        provider_new_partnership_academic_cycles_path(provider)
      end

      def back_path
        return provider_new_partnership_confirm_path(provider) if params[:goto] == "confirm"

        provider_new_partnership_find_path(provider)
      end

      def build_form_from_session(partnership_data)
        return ::Partnerships::DatesForm.new unless partnership_data&.dig(:start_date)

        dates_object = DateValues.new(
          start_date: partnership_data[:start_date],
          end_date: partnership_data[:end_date]
        )
        ::Partnerships::DatesForm.from_dates(dates_object)
      end

      def form_url
        provider_partnership_dates_path(provider)
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
        @form_method = :post
        @cancel_path = cancel_path
        @page_title = "Partnership dates"
        @page_subtitle = page_subtitle
        @page_caption = page_caption
      end
    end
  end
end
