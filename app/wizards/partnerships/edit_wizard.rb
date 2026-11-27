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
        partnership_types: partnership.partnership_types.kept.pluck(:partnership_type),
        seeded_ended: partnership.ended_on?
      )
    end

    def used_partnership_types
      @used_partnership_types ||= PartnershipType.used_between(
        accredited_provider_id: partnership.accredited_provider_id,
        provider_id: partnership.provider_id,
        except_partnership_id: partnership.id
      )
    end

    # Saving a type change on a partnership that is already running ends it
    # today and starts a replacement, so the answers have to be valid for that
    # replacement rather than for the existing record.
    def revises_partnership?(on: Time.zone.today)
      return false unless partnership.can_be_ended?(on:)

      selected_types = Array(selected_partnership_types).map(&:to_s).uniq.sort
      selected_types != partnership.partnership_types.kept.map(&:partnership_type).sort
    end

    def partnership_form
      form = super
      return form unless revises_partnership?

      # The replacement starts today, so the years it can carry are the ones that
      # overlap it, plus the years already attached to the partnership — those were
      # chosen for the record being ended and are carried over to its replacement.
      form.revision_on = Time.zone.today
      form.eligible_academic_year_ids =
        (eligible_academic_years(start_date: Time.zone.today).pluck(:id).map(&:to_s) +
         partnership.academic_year_ids.map(&:to_s)).uniq
      form
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
