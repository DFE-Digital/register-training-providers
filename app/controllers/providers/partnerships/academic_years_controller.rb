module Providers
  module Partnerships
    class AcademicYearsController < ApplicationController
      include PartnershipJourneyController

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

        @form = ::Partnerships::AcademicYearsForm.new(
          academic_year_ids: params.dig(:select, :academic_year_ids).compact_blank!
        )

        partnership_data = partnership_session.load_partnership || {}

        if @form.valid?
          merged_attributes = partnership_data.merge(academic_year_ids: @form.academic_year_ids)
          partnership_session.store_partnership(merged_attributes)
          redirect_to provider_partnership_check_path(@partnership, provider_id: provider.id)
        else
          setup_view_data
          render :new, status: :unprocessable_content
        end
      end

    private

      def build_form_for_edit(partnership_data, partnership)
        if partnership_data&.dig(:academic_year_ids)
          ::Partnerships::AcademicYearsForm.new(academic_year_ids: partnership_data[:academic_year_ids])
        else
          ::Partnerships::AcademicYearsForm.new(academic_year_ids: partnership.academic_year_ids)
        end
      end

      def back_path
        if params[:goto] == "confirm"
          provider_partnership_check_path(@partnership, provider_id: provider.id)
        else
          provider_edit_partnership_dates_path(@partnership, provider_id: provider.id)
        end
      end

      def form_url
        provider_edit_partnership_academic_years_path(@partnership, provider_id: provider.id, goto: params[:goto])
      end

      def cancel_path
        provider_partnerships_path(provider)
      end

      def setup_view_data
        @back_path = back_path
        @form_url = form_url
        @form_method = :patch
        @cancel_path = cancel_path
        @page_title = "Academic year"
        @page_subtitle = provider.operating_name.to_s
        @page_caption = provider.operating_name.to_s
        @academic_years = academic_years
      end

      def partnership_data
        partnership_session.load_partnership
      end

      def partnership_start_date
        partnership_data&.dig(:start_date) || @partnership&.duration&.begin
      end

      def partnership_end_date
        session_end_date = partnership_data&.dig(:end_date)
        return session_end_date if session_end_date.is_a?(Date)

        partnership_end = @partnership&.duration&.end
        return partnership_end if partnership_end.is_a?(Date)

        default_end_date
      end

      def default_end_date
        next_year_date = Time.zone.today + 1.year
        fallback_date = Time.zone.today + 2.years

        AcademicYear.find_by("duration @> ?::date", next_year_date)&.duration&.end || fallback_date
      end

      def academic_years
        start_date = partnership_start_date
        end_date = partnership_end_date

        AcademicYear.where("duration && daterange(?, ?)", start_date, end_date).order(duration: :desc)
      end
    end
  end
end
