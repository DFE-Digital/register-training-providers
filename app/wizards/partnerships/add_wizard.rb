module Partnerships
  class AddWizard < BaseWizard
    def steps_processor
      build_steps_processor(
        root: :find_partner,
        edges: [
          [:find_partner, :types],
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
      build_route_strategy(:provider_partnership_step_path, { provider_id: provider.id })
    end

    def accredited_provider_id
      provider.accredited? ? provider.id : wizard_state[:partner_id]
    end

    def training_provider_id
      provider.accredited? ? wizard_state[:partner_id] : provider.id
    end

    def partner
      return @partner if defined?(@partner)

      @partner = Provider.find_by(id: wizard_state[:partner_id])
    end

    def eligible_partners
      partners = if provider.accredited?
                   Provider.kept.unaccredited
                 else
                   Provider.kept.accredited
                 end

      partners.where(archived_at: nil)
    end

    def used_partnership_types
      return [] if partner.blank?

      @used_partnership_types ||= PartnershipType.used_between(
        accredited_provider_id: accredited_provider_id,
        provider_id: training_provider_id
      )
    end

    def available_partnership_types
      @available_partnership_types ||= begin
        available = PartnershipTypeEnum::PARTNERSHIP_TYPES.values - used_partnership_types

        available.delete(PartnershipTypeEnum::PLACEMENT) unless placement_available?

        available
      end
    end

    def placement_available?
      return @placement_available if defined?(@placement_available)

      @placement_available = training_partner&.school? || false
    end

    def selected_partnership_types
      Array(wizard_state[:partnership_types]).compact_blank
    end

  private

    def training_partner
      provider.accredited? ? partner : provider
    end

    def steps
      {
        find_partner: Steps::FindPartnerStep,
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
