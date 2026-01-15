module Providers
  module Partnerships
    class AcademicCyclesController < ApplicationController
      include PartnershipJourneyController

      def new
        partnership_data = partnership_session.load_partnership

        # Keep previous selections only when coming from confirm page to change them
        # Otherwise start fresh (dates may have changed, invalidating previous selections)
        previous_ids = params[:goto] == "confirm" ? partnership_data&.dig(:academic_cycle_ids) : nil
        @form = ::Partnerships::AcademicCyclesForm.new(
          academic_cycle_ids: previous_ids || []
        )

        setup_view_data
      end

      def create
        @form = ::Partnerships::AcademicCyclesForm.new(
          academic_cycle_ids: params.dig(:select, :academic_cycle_ids).compact_blank!,
        )

        partnership_attributes = partnership_session.load_partnership

        if @form.valid?
          merged_attributes = partnership_attributes.merge(academic_cycle_ids: @form.academic_cycle_ids)
          partnership_session.store_partnership(merged_attributes)
          redirect_to check_path
        else
          setup_view_data
          render :new
        end
      end

    private

      def check_path
        provider_new_partnership_confirm_path(provider)
      end

      def back_path
        return provider_new_partnership_confirm_path(provider) if params[:goto] == "confirm"

        provider_new_partnership_dates_path(provider)
      end

      def form_url
        provider_partnership_academic_cycles_path(provider)
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
        @page_title = "Academic year"
        @page_subtitle = page_subtitle
        @page_caption = page_caption
        @academic_cycles = academic_cycles
      end

      def partnership_data
        partnership_session.load_partnership
      end

      def accredited_provider
        return provider if provider.accredited?

        Provider.find(partnership_data[:partner_id])
      end

      def partnership_start_date
        partnership_data[:start_date]
      end

      def next_academic_cycle_end
        next_year_date = Time.zone.today + 1.year
        fallback_date = Time.zone.today + 2.years
        AcademicCycle.find_by("duration @> ?::date", next_year_date)&.duration&.end || fallback_date
      end

      def academic_cycles
        AcademicCycle.where("duration && daterange(?, ?)", partnership_start_date, next_academic_cycle_end)
      end
    end
  end
end
