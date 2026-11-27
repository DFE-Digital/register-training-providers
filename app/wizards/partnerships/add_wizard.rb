module Partnerships
  class AddWizard
    include DfE::Wizard

    attr_reader :provider

    def initialize(provider:, **)
      @provider = provider
      super(**)
    end

    def steps_processor
      DfE::Wizard::StepsProcessor::Graph.draw(self, predicate_caller: state_store) do |graph|
        steps.each { |name, klass| graph.add_node(name, klass) }

        graph.root :find_partner
        graph.add_edge from: :find_partner, to: :dates
        graph.add_edge from: :dates, to: :academic_years
        graph.add_edge from: :academic_years, to: :check_your_answers

        graph.before_next_step(:next_step_override)
        graph.before_previous_step(:previous_step_override)
      end
    end

    def next_step_override
      :check_your_answers if return_to_review? && valid_path_to?(:check_your_answers)
    end

    def previous_step_override
      :check_your_answers if return_to_review? && valid_path_to?(:check_your_answers)
    end

    def route_strategy
      DfE::Wizard::RouteStrategy::ConfigurableRoutes.new(wizard: self, namespace: "partnerships") do |config|
        config.default_path_arguments = { provider_id: provider.id }

        steps.each_key do |step|
          config.map_step step, to: lambda { |_wizard, options, helpers|
            helpers.provider_new_partnership_step_path(step: step.to_s.tr("_", "-"), **options)
          }
        end
      end
    end

    def check_your_answers?
      current_step_name == :check_your_answers
    end

    def first_step?
      current_step_name == :find_partner
    end

    def eligible_partners
      partners = if provider.accredited?
                   Provider.kept.unaccredited
                 else
                   Provider.kept.accredited
                 end

      partners.where(archived_at: nil)
    end

    def partnership_form
      state = wizard_state

      ::PartnershipForm.new(
        accredited_provider_id: accredited_provider_id(state),
        provider_id: training_provider_id(state),
        start_date_day: state[:start_date_day],
        start_date_month: state[:start_date_month],
        start_date_year: state[:start_date_year],
        end_date_day: state[:end_date_day],
        end_date_month: state[:end_date_month],
        end_date_year: state[:end_date_year],
        academic_year_ids: Array(state[:academic_year_ids])
      )
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

    def wizard_state
      state_store.read.with_indifferent_access
    end

    def return_to_review?
      @current_step_params[:return_to_review].present?
    end

    def accredited_provider_id(state)
      provider.accredited? ? provider.id : state[:partner_id]
    end

    def training_provider_id(state)
      provider.accredited? ? state[:partner_id] : provider.id
    end
  end
end
