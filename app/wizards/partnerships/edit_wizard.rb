module Partnerships
  class EditWizard < BaseWizard
    attr_reader :partnership

    def initialize(partnership:, **)
      @partnership = partnership
      super(**)
    end

    def steps_processor
      build_steps_processor(
        root: :dates,
        edges: [
          [:dates, :academic_years],
          [:academic_years, :check_your_answers]
        ]
      )
    end

    def route_strategy
      build_route_strategy(
        :provider_partnership_edit_step_path,
        { provider_id: provider.id, partnership_id: partnership.id }
      )
    end

    def seed_from_partnership
      duration = partnership.duration
      ending = duration.end.is_a?(Date) ? duration.end : nil

      state_store.write(
        start_date: duration.begin,
        end_date: ending,
        start_date_day: duration.begin.day,
        start_date_month: duration.begin.month,
        start_date_year: duration.begin.year,
        end_date_day: ending&.day,
        end_date_month: ending&.month,
        end_date_year: ending&.year,
        academic_year_ids: partnership.academic_year_ids.uniq
      )
    end

    delegate :accredited_provider_id, to: :partnership

    def training_provider_id
      partnership.provider_id
    end

  private

    def steps
      {
        dates: Steps::DatesStep,
        academic_years: Steps::AcademicYearsStep,
        check_your_answers: Steps::CheckYourAnswersStep
      }
    end
  end
end
