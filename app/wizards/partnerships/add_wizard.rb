module Partnerships
  class AddWizard < BaseWizard
    def steps_processor
      build_steps_processor(
        root: :find_partner,
        edges: [
          [:find_partner, :dates],
          [:dates, :academic_years],
          [:academic_years, :check_your_answers]
        ]
      )
    end

    def route_strategy
      build_route_strategy(:provider_new_partnership_step_path, { provider_id: provider.id })
    end

    def accredited_provider_id
      provider.accredited? ? provider.id : wizard_state[:partner_id]
    end

    def training_provider_id
      provider.accredited? ? wizard_state[:partner_id] : provider.id
    end

    def eligible_partners
      partners = if provider.accredited?
                   Provider.kept.unaccredited
                 else
                   Provider.kept.accredited
                 end

      partners.where(archived_at: nil)
    end

  private

    def steps
      {
        find_partner: Steps::FindPartnerStep,
        dates: Steps::DatesStep,
        academic_years: Steps::AcademicYearsStep,
        check_your_answers: Steps::CheckYourAnswersStep
      }
    end
  end
end
