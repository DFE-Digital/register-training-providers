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
        @form = ::Partnerships::AcademicCyclesForm.new(
          academic_cycle_ids: params.dig(:select, :academic_cycle_ids).compact_blank!,
        )

        partnership_attributes = partnership_session.load_partnership

        unless partnership_attributes
          redirect_to provider_new_partnership_find_path(provider)
          return
        end

        if @form.valid?
          merged_attributes = partnership_attributes.merge(academic_cycle_ids: @form.academic_cycle_ids)
          partnership_session.store_partnership(merged_attributes)
          redirect_to provider_new_partnership_confirm_path(provider)
        else
          setup_view_data(:new)
          render :new
        end
      end

      def update
        @partnership = provider.partnerships.kept.find(params[:id])
        authorize @partnership

        @form = ::Partnerships::AcademicCyclesForm.new(
          academic_cycle_ids: params.dig(:select, :academic_cycle_ids).compact_blank!,
        )

        partnership_data = partnership_session.load_partnership || {}

        if @form.valid?
          merged_attributes = partnership_data.merge(academic_cycle_ids: @form.academic_cycle_ids)
          partnership_session.store_partnership(merged_attributes)
          redirect_to provider_partnership_check_path(@partnership, provider_id: provider.id)
        else
          setup_view_data(:edit)
          render :new
        end
      end

    private

      def build_form_for_edit(partnership_data, partnership)
        if partnership_data&.dig(:academic_cycle_ids)
          ::Partnerships::AcademicCyclesForm.new(academic_cycle_ids: partnership_data[:academic_cycle_ids])
        else
          ::Partnerships::AcademicCyclesForm.new(academic_cycle_ids: partnership.academic_cycle_ids)
        end
      end

      def back_path(context)
        if context == :edit && params[:goto] == "confirm"
          provider_partnership_check_path(@partnership, provider_id: provider.id)
        elsif context == :edit
          provider_edit_partnership_dates_path(@partnership, provider_id: provider.id)
        elsif params[:goto] == "confirm"
          provider_new_partnership_confirm_path(provider)
        else
          provider_new_partnership_dates_path(provider)
        end
      end

      def form_url(context)
        if context == :edit
          provider_edit_partnership_academic_cycles_path(@partnership, provider_id: provider.id, goto: params[:goto])
        else
          provider_partnership_academic_cycles_path(provider, goto: params[:goto])
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
        @page_title = "Academic year"
        @page_subtitle = provider.operating_name.to_s
        @page_caption = page_caption(context)
        @academic_cycles = academic_cycles(context)
      end

      def partnership_data
        partnership_session.load_partnership
      end

      def partnership_start_date(context)
        if context == :edit && partnership_data&.dig(:start_date)
          partnership_data[:start_date]
        elsif context == :edit && @partnership
          @partnership.duration.begin
        else
          partnership_data&.dig(:start_date)
        end
      end

      def partnership_end_date(context)
        # Check session first (user may have just entered a new end date)
        session_end_date = partnership_data&.dig(:end_date)
        return session_end_date if session_end_date.is_a?(Date)

        # For edit context, check existing partnership
        if context == :edit && @partnership
          partnership_end = @partnership.duration.end
          return partnership_end if partnership_end.is_a?(Date)
        end

        # Fall back to next academic cycle end for open-ended partnerships
        default_end_date
      end

      def default_end_date
        next_year_date = Time.zone.today + 1.year
        fallback_date = Time.zone.today + 2.years
        AcademicCycle.find_by("duration @> ?::date", next_year_date)&.duration&.end || fallback_date
      end

      def academic_cycles(context)
        start_date = partnership_start_date(context)
        end_date = partnership_end_date(context)
        AcademicCycle.where("duration && daterange(?, ?)", start_date, end_date)
      end
    end
  end
end
