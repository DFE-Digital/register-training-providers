module Partnerships
  class EditWizard < BaseWizard
    attr_reader :partnership

    def initialize(partnership:, **)
      @partnership = partnership
      super(**)
    end

    def steps_processor
      build_steps_processor(
        root: :types,
        edges: [
          [:types, :start_date],
          [:start_date, :end_date_question],
          [:end_date, :academic_years],
          [:academic_years, :check_your_answers]
        ],
        conditional_edges: [
          {
            from: :end_date_question,
            when: :has_end_date?,
            then: :end_date,
            else: :academic_years
          }
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
        start_today: duration.begin == Time.zone.today ? "true" : "false",
        has_end_date: ending.present? ? "true" : "false",
        end_date: ending,
        start_date_day: duration.begin.day,
        start_date_month: duration.begin.month,
        start_date_year: duration.begin.year,
        end_date_day: ending&.day,
        end_date_month: ending&.month,
        end_date_year: ending&.year,
        academic_year_ids: partnership.academic_year_ids.uniq,
        partnership_types: partnership.partnership_types.kept.pluck(:partnership_type)
      )
    end

    def used_partnership_types
      @used_partnership_types ||= PartnershipType.used_between(
        accredited_provider_id: partnership.accredited_provider_id,
        provider_id: partnership.provider_id,
        except_partnership_id: partnership.id
      )
    end

    def available_partnership_types
      @available_partnership_types ||= begin
        selected = selected_partnership_types
        available = PartnershipTypeEnum::PARTNERSHIP_TYPES.values - used_partnership_types
        unless placement_available? || selected.include?(PartnershipTypeEnum::PLACEMENT)
          available.delete(PartnershipTypeEnum::PLACEMENT)
        end

        available
      end
    end

    def placement_available?
      partnership.provider.school?
    end

    def selected_partnership_types
      Array(wizard_state[:partnership_types]).compact_blank
    end

    delegate :accredited_provider_id, to: :partnership

    def training_provider_id
      partnership.provider_id
    end

  private

    def steps
      {
        types: Steps::TypesStep,
        start_date: Steps::StartDateStep,
        end_date_question: Steps::EndDateQuestionStep,
        end_date: Steps::EndDateStep,
        academic_years: Steps::AcademicYearsStep,
        check_your_answers: Steps::CheckYourAnswersStep
      }
    end
  end
end
