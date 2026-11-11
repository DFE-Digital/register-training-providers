module Providers
  module Partnerships
    class DatesController < ApplicationController
      include PartnershipJourneyController

      DateValues = Struct.new(:start_date, :end_date)

      def edit
        @partnership = provider.partnerships.kept.find(params[:id])
        authorize @partnership

        partnership_data = partnership_session.load_partnership
        @form = build_form_for_edit(partnership_data, @partnership)

        setup_view_data
        render :new
      end

      def update
        @partnership = provider.partnerships.kept.find(params[:id])
        authorize @partnership

        @form = ::Partnerships::DatesForm.new(dates_form_params)

        partnership_data = partnership_session.load_partnership || {}

        if @form.valid?
          partnership_session.store_partnership(partnership_data.merge(@form.attributes))

          redirect_to next_path
        else
          setup_view_data
          render :new, status: :unprocessable_content
        end
      end

    private

      def dates_form_params
        params.expect(partnerships_dates_form: [*::Partnerships::DatesForm::PARAM_CONVERSION.keys])
          .transform_keys { |k| ::Partnerships::DatesForm::PARAM_CONVERSION.fetch(k, k) }
      end

      def next_path
        provider_edit_partnership_academic_years_path(@partnership, provider_id: provider.id, goto: params[:goto])
      end

      def back_path
        if params[:goto] == "confirm"
          provider_partnership_check_path(@partnership, provider_id: provider.id)
        else
          provider_partnerships_path(provider)
        end
      end

      def build_form_for_edit(partnership_data, partnership)
        dates_object = if partnership_data&.dig(:start_date)
                         DateValues.new(
                           start_date: partnership_data[:start_date],
                           end_date: partnership_data[:end_date]
                         )
                       else
                         DateValues.new(
                           start_date: partnership.duration.begin,
                           end_date: partnership.duration.end.is_a?(Date) ? partnership.duration.end : nil
                         )
                       end
        ::Partnerships::DatesForm.from_dates(dates_object)
      end

      def form_url
        provider_edit_partnership_dates_path(@partnership, provider_id: provider.id, goto: params[:goto])
      end

      def cancel_path
        provider_partnerships_path(provider)
      end

      def setup_view_data
        @back_path = back_path
        @form_url = form_url
        @form_method = :patch
        @cancel_path = cancel_path
        @page_title = "Partnership dates"
        @page_subtitle = provider.operating_name.to_s
        @page_caption = provider.operating_name.to_s
      end
    end
  end
end
